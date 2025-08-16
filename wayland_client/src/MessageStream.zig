const std = @import("std");
const builtin = @import("builtin");
const UnixStream = @import("UnixStream.zig");

const native_endian = builtin.cpu.arch.endian();

pub const Message = @import("Message.zig");

const MessageStream = @This();
const types = @import("types.zig");

stream: UnixStream,
writer: UnixStream.Writer,
reader: UnixStream.Reader,
allocator: std.mem.Allocator,
writer_buffer: []u8,
reader_buffer: []u8,
fd_buffer: []align(@alignOf(std.posix.fd_t)) u8,

pub fn init(allocator: std.mem.Allocator) !MessageStream {
    var envs = try std.process.getEnvMap(allocator);
    defer envs.deinit();

    const wayland_socket_env = envs.get("WAYLAND_SOCKET");

    const stream = if (wayland_socket_env) |wayland_socket_str|
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
    errdefer stream.close();

    const writer_buffer = try allocator.alloc(u8, 1024);
    const reader_buffer = try allocator.alloc(u8, 1024);
    const fd_buffer = try allocator.alignedAlloc(u8, std.mem.Alignment.fromByteUnits(@alignOf(std.posix.fd_t)), 1024);

    const writer = stream.writer(writer_buffer);
    const reader = stream.reader(reader_buffer, fd_buffer);

    return MessageStream{
        .stream = stream,
        .allocator = allocator,
        .writer = writer,
        .reader = reader,
        .writer_buffer = writer_buffer,
        .reader_buffer = reader_buffer,
        .fd_buffer = fd_buffer,
    };
}

pub fn deinit(self: *const MessageStream) void {
    self.allocator.free(self.writer_buffer);
    self.allocator.free(self.reader_buffer);
    self.allocator.free(self.fd_buffer);
    self.stream.close();
}

const MAX_FD_RECV: usize = 32;

const Header = packed struct(u32) {
    opcode: u16,
    size: u16,
};

pub fn next(self: *MessageStream) !Message {
    const info_len = @sizeOf(types.ObjectId) + @sizeOf(Header);

    var fds = std.array_list.Managed(std.posix.fd_t).init(self.allocator);
    errdefer fds.deinit();

    const id = try self.reader.interface.takeInt(types.ObjectId, native_endian);

    if (self.reader.fd_buffer) |f| {
        try fds.appendSlice(f);
    }

    const header: Header = @bitCast(try self.reader.interface.takeInt(u32, native_endian));
    if (self.reader.fd_buffer) |f| {
        try fds.appendSlice(f);
    }

    const body_buf = try self.reader.interface.readAlloc(self.allocator, @as(usize, @intCast(@as(i32, @intCast(header.size)) - info_len)));
    errdefer self.allocator.free(body_buf);
    if (self.reader.fd_buffer) |f| {
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

pub fn send(self: *MessageStream, message: Message) !void {
    try self.writer.interface.writeInt(types.ObjectId, message.info.object, native_endian);
    try self.writer.interface.writeInt(u32, @bitCast(Header{
        .opcode = message.info.opcode,
        .size = @intCast(message.data.len + 8),
    }), native_endian);
    for (message.fd_list) |fd| {
        var b = [0]u8{};
        var reader = (std.fs.File{ .handle = fd }).reader(&b);
        _ = try self.writer.interface.sendFile(&reader, .unlimited);
    }
    try self.writer.interface.writeAll(message.data);

    try self.writer.interface.flush();
}
