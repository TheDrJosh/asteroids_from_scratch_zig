const std = @import("std");
const builtin = @import("builtin");
const unix_domain_socket = @import("unix_domain_socket.zig");

const native_endian = builtin.cpu.arch.endian();

const Message = @import("Message.zig");

pub const WaylandStream = @This();
const types = @import("types.zig");

socket: std.posix.socket_t,
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) !WaylandStream {
    var envs = try std.process.getEnvMap(allocator);
    defer envs.deinit();

    const wayland_socket_env = envs.get("WAYLAND_SOCKET");

    const socket = try if (wayland_socket_env) |wayland_socket_str| std.fmt.parseInt(std.posix.fd_t, wayland_socket_str, 10) else blk: {
        const socket = try unix_domain_socket.createUnixSocket();
        errdefer std.posix.close(socket);
        const xdg_runtime_dir_env = envs.get("XDG_RUNTIME_DIR") orelse return error.unable_to_connect_to_wayland_server;
        const wayland_display_env = envs.get("WAYLAND_DISPLAY") orelse "wayland-0";

        const addr = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ xdg_runtime_dir_env, wayland_display_env });
        defer allocator.free(addr);

        try unix_domain_socket.connectUnixSocket(socket, addr);

        break :blk socket;
    };

    return WaylandStream{
        .socket = socket,
        .allocator = allocator,
    };
}

pub fn deinit(self: *const WaylandStream) void {
    std.posix.close(self.socket);
}

const MAX_FD_RECV: usize = 32;

const Header = packed struct(u32) {
    opcode: u16,
    size: u16,
};

pub fn next(self: *const WaylandStream) !?Message {
    const info_len = @sizeOf(types.ObjectId) + @sizeOf(Header);

    var header_buf = [1]u8{0} ** info_len;
    var fds_buf = [1]std.posix.fd_t{0} ** MAX_FD_RECV;

    const header_len = unix_domain_socket.recvFdsWithData(
        self.socket,
        &fds_buf,
        &header_buf,
        self.allocator,
    ) catch |e| {
        switch (e) {
            error.WouldBlock => return null,
            else => return e,
        }
    };

    std.debug.assert(header_len.data_received == info_len);

    const id = std.mem.readInt(types.ObjectId, header_buf[0..@sizeOf(types.ObjectId)], native_endian);
    const header: Header = @bitCast(std.mem.readInt(u32, header_buf[@sizeOf(types.ObjectId)..], native_endian));

    // std.debug.print("id: {}, opcode: {}, len: {}\n", .{ id, header.opcode, header.size });

    const body_buf = try self.allocator.alloc(u8, @as(usize, @intCast(@as(i32, @intCast(header.size)) - info_len)));
    errdefer self.allocator.free(body_buf);

    const body_len = try unix_domain_socket.recvFdsWithData(self.socket, fds_buf[header_len.fds_received..], body_buf, self.allocator);

    std.debug.assert(body_len.data_received == (header.size - info_len));
    std.debug.assert((body_len.fds_received + header_len.fds_received) < MAX_FD_RECV);

    const fd_buf_alloc = try self.allocator.alloc(std.posix.fd_t, body_len.fds_received + header_len.fds_received);
    errdefer self.allocator.free(fd_buf_alloc);

    @memcpy(fd_buf_alloc, fds_buf[0..(body_len.fds_received + header_len.fds_received)]);

    return Message{
        .info = .{
            .object = id,
            .opcode = header.opcode,
        },
        .data = body_buf,
        .fd_list = fd_buf_alloc,
        .allocator = self.allocator,
    };
}

pub fn send(self: *const WaylandStream, message: Message) !void {
    var object_id_bytes = [_]u8{0} ** @sizeOf(types.ObjectId);
    std.mem.writeInt(types.ObjectId, &object_id_bytes, message.info.object, native_endian);
    var header_bytes = [_]u8{0} ** @sizeOf(Header);
    std.mem.writeInt(u32, &header_bytes, @bitCast(Header{
        .opcode = message.info.opcode,
        .size = @intCast(message.data.len + 8),
    }), native_endian);

    std.debug.assert(try std.posix.send(self.socket, &object_id_bytes, 0) == object_id_bytes.len);
    std.debug.assert(try std.posix.send(self.socket, &header_bytes, 0) == header_bytes.len);

    try unix_domain_socket.sendFdsWithData(self.socket, message.fd_list, message.data, self.allocator);
}
