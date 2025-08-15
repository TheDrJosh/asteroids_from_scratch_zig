const std = @import("std");
const builtin = @import("builtin");
const UnixStream = @import("UnixStream.zig");

const native_endian = builtin.cpu.arch.endian();

const Message = @import("Message.zig");

pub const WaylandStream = @This();
const types = @import("types.zig");

socket: UnixStream,
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) !WaylandStream {
    var envs = try std.process.getEnvMap(allocator);
    defer envs.deinit();

    const wayland_socket_env = envs.get("WAYLAND_SOCKET");

    const socket = if (wayland_socket_env) |wayland_socket_str|
        UnixStream{
            .handle = try std.fmt.parseInt(std.posix.fd_t, wayland_socket_str, 10),
        }
    else blk: {
        const xdg_runtime_dir_env = envs.get("XDG_RUNTIME_DIR") orelse return error.unable_to_connect_to_wayland_server;
        const wayland_display_env = envs.get("WAYLAND_DISPLAY") orelse "wayland-0";

        const addr = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ xdg_runtime_dir_env, wayland_display_env });
        defer allocator.free(addr);

        break :blk try UnixStream.open(addr);
    };
    errdefer socket.close();

    return WaylandStream{
        .socket = socket,
        .allocator = allocator,
    };
}

pub fn deinit(self: *const WaylandStream) void {
    self.socket.close();
}

const MAX_FD_RECV: usize = 32;

const Header = packed struct(u32) {
    opcode: u16,
    size: u16,
};

pub fn next(self: *const WaylandStream) !Message {
    const info_len = @sizeOf(types.ObjectId) + @sizeOf(Header);

    var fds = std.array_list.Managed(std.posix.fd_t).init(self.allocator);
    errdefer fds.deinit();

    //TODO test buffer sizes
    var buffer: [1024]u8 = undefined;
    //TODO test buffer sizes
    var fd_buffer: [128]u8 align(@alignOf(std.posix.fd_t)) = undefined;

    var reader = self.socket.reader(&buffer, &fd_buffer);

    const id = try reader.interface.takeInt(types.ObjectId, native_endian);

    if (reader.fd_buffer) |f| {
        try fds.appendSlice(f);
    }

    const header: Header = @bitCast(try reader.interface.takeInt(u32, native_endian));
    if (reader.fd_buffer) |f| {
        try fds.appendSlice(f);
    }

    const body_buf = try reader.interface.readAlloc(self.allocator, @as(usize, @intCast(@as(i32, @intCast(header.size)) - info_len)));
    errdefer self.allocator.free(body_buf);
    if (reader.fd_buffer) |f| {
        try fds.appendSlice(f);
    }

    return Message{
        .info = .{
            .object = id,
            .opcode = header.opcode,
        },
        .data = body_buf,
        .fd_list = try fds.toOwnedSlice(),
        .allocator = self.allocator,
    };
}

pub fn send(self: *const WaylandStream, message: Message) !void {
    //TODO test buffer sizes
    var buffer: [1024]u8 = undefined;

    var writer = self.socket.writer(&buffer);

    try writer.interface.writeInt(types.ObjectId, message.info.object, native_endian);
    try writer.interface.writeInt(u32, @bitCast(Header{
        .opcode = message.info.opcode,
        .size = @intCast(message.data.len + 8),
    }), native_endian);
    for (message.fd_list) |fd| {
        var b = [0]u8{};
        var reader = (std.fs.File{ .handle = fd }).reader(&b);
        _ = try writer.interface.sendFile(&reader, .unlimited);
    }
    try writer.interface.writeAll(message.data);

    try writer.interface.flush();
}
