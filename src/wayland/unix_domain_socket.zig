const std = @import("std");
const c = @cImport(@cInclude("unix_domain_socket_lib.h"));

/// Create a Unix domain socket
pub fn createUnixSocket() !std.posix.socket_t {
    return std.posix.socket(std.posix.AF.UNIX, std.posix.SOCK.STREAM, 0) catch |err| {
        std.debug.print("Failed to create socket: {}\n", .{err});
        return error.SocketCreationFailed;
    };
}

/// Connect to a Unix domain socket
pub fn connectUnixSocket(sockfd: std.posix.socket_t, path: []const u8) !void {
    var addr = std.posix.sockaddr.un{
        .family = std.posix.AF.UNIX,
        .path = undefined,
    };

    if (path.len >= addr.path.len) {
        return error.InvalidAddress;
    }

    @memset(&addr.path, 0);
    @memcpy(addr.path[0..path.len], path);

    const addr_ptr = @as(*const std.posix.sockaddr, @ptrCast(&addr));
    const addr_len = @as(std.posix.socklen_t, @sizeOf(std.posix.sockaddr.un));

    std.posix.connect(sockfd, addr_ptr, addr_len) catch |err| {
        std.debug.print("Failed to connect socket: {}\n", .{err});
        return error.ConnectFailed;
    };
}

pub fn sendFdsWithData(socket_fd: std.posix.socket_t, fds_to_send: []const std.posix.fd_t, data: []const u8) !void {
    switch (c.send_fds_with_data(socket_fd, @constCast(fds_to_send.ptr), fds_to_send.len, @constCast(data.ptr), data.len)) {
        0 => {},
        -1 => return error.sendmsg,
        else => unreachable,
    }
}

pub fn recvFdsWithData(
    socket_fd: std.posix.socket_t,
    received_fds: []std.posix.fd_t,
    data_buf: []u8,
) !struct { fds_received: usize, data_received: usize } {
    var data_received: usize = 0;
    switch (c.recv_fds_with_data(socket_fd, received_fds.ptr, received_fds.len, data_buf.ptr, data_buf.len, &data_received)) {
        -1 => return error.recvmsg,
        -2 => return error.received_more_fds_than_expected,
        std.math.minInt(c_int)...-3 => unreachable,
        else => |fds_received| {
            return .{
                .data_received = data_received,
                .fds_received = @intCast(fds_received),
            };
        },
    }
}
