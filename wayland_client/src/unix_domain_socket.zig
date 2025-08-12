const std = @import("std");

/// Create a Unix domain socket
pub fn createUnixSocket() !std.posix.socket_t {
    return std.posix.socket(
        std.posix.AF.UNIX,
        std.posix.SOCK.STREAM | std.posix.SOCK.NONBLOCK,
        0,
    ) catch |err| {
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

pub fn sendFdsWithData(socket_fd: std.posix.socket_t, fds_to_send: []const std.posix.fd_t, data: []const u8, allocator: std.mem.Allocator) !void {
    if (data.len == 0) {
        if (fds_to_send.len != 0) {
            std.debug.panic("unable to send fds without data", .{});
        }
        return;
    }

    var cmsgbuf = try allocator.alignedAlloc(u8, std.mem.Alignment.of(cmsghdr), cmsg_space(@sizeOf(std.posix.fd_t) * fds_to_send.len));
    defer allocator.free(cmsgbuf);

    var cmsg: *cmsghdr = @ptrCast(cmsgbuf.ptr);

    if (fds_to_send.len > 0) {
        cmsg.level = std.posix.SOL.SOCKET;
        cmsg.type = SCM_RIGHTS;
        cmsg.len = @intCast(cmsg_len(@sizeOf(std.posix.fd_t) * fds_to_send.len));

        var fds = std.mem.bytesAsSlice(std.posix.fd_t, cmsgbuf[@sizeOf(cmsghdr)..]);
        @memcpy(fds[0..fds_to_send.len], fds_to_send);
    }

    const n = try std.posix.sendmsg(socket_fd, &std.posix.msghdr_const{
        .name = null,
        .namelen = 0,
        .iov = &[1]std.posix.iovec_const{std.posix.iovec_const{
            .base = data.ptr,
            .len = data.len,
        }},
        .iovlen = 1,
        .control = if (fds_to_send.len > 0) cmsgbuf.ptr else null,
        .controllen = @intCast(if (fds_to_send.len > 0) cmsgbuf.len else 0),
        .flags = 0,
    }, 0);

    std.debug.assert(n == data.len);
}

pub fn recvFdsWithData(
    socket_fd: std.posix.socket_t,
    received_fds: []std.posix.fd_t,
    data_buf: []u8,
    allocator: std.mem.Allocator,
) !struct { fds_received: usize, data_received: usize } {
    if (data_buf.len == 0) {
        return .{
            .fds_received = 0,
            .data_received = 0,
        };
    }

    var iov = [1]std.posix.iovec{std.posix.iovec{
        .base = data_buf.ptr,
        .len = data_buf.len,
    }};

    var cmsgbuf = try allocator.alignedAlloc(u8, std.mem.Alignment.of(cmsghdr), cmsg_space(@sizeOf(std.posix.fd_t) * received_fds.len));
    defer allocator.free(cmsgbuf);

    var msg = std.posix.msghdr{
        .name = null,
        .namelen = 0,
        .iov = &iov,
        .iovlen = 1,
        .control = cmsgbuf.ptr,
        .controllen = @intCast(cmsgbuf.len),
        .flags = 0,
    };

    const n = try recvmsg(socket_fd, &msg, 0);

    if (msg.control) |ctl| {
        const cmsg: *const cmsghdr = @ptrCast(&ctl);
        if (cmsg.level == std.posix.SOL.SOCKET and cmsg.type == SCM_RIGHTS) {
            const num_fds = (cmsg.len - cmsg_len(0)) / @sizeOf(std.posix.fd_t);

            const fds = std.mem.bytesAsSlice(std.posix.fd_t, cmsgbuf[@sizeOf(cmsghdr)..]);

            @memcpy(received_fds[0..num_fds], fds);

            return .{
                .data_received = n,
                .fds_received = num_fds,
            };
        }
    }

    return .{
        .data_received = n,
        .fds_received = 0,
    };
}

// From https://github.com/ziglang/zig/pull/24603 until this gets merged
pub const RecvMsgError = error{
    InputOutput,
} || std.posix.RecvFromError;

pub fn recvmsg(sockfd: std.posix.socket_t, msg: *std.posix.msghdr, flags: u32) RecvMsgError!usize {
    while (true) {
        const rc = std.posix.system.recvmsg(sockfd, msg, flags);
        switch (std.posix.errno(rc)) {
            .SUCCESS => return @intCast(rc),

            .AGAIN => return error.WouldBlock,
            .CONNREFUSED => return error.ConnectionRefused,
            .CONNRESET => return error.ConnectionResetByPeer,
            .IO => return error.InputOutput,
            .MSGSIZE => return error.MessageTooBig,
            .NOBUFS => return error.SystemResources,
            .NOMEM => return error.SystemResources,
            .NOTCONN => return error.SocketNotConnected,
            .TIMEDOUT => return error.ConnectionTimedOut,
            .INTR => continue,
            .BADF => unreachable,
            .FAULT => unreachable,
            .INVAL => unreachable,
            .NOTSOCK => unreachable, // the socket descriptor does not refer to a socket
            .OPNOTSUPP => unreachable, // Some bit in the flags argument is inappropriate for the socket type.
            else => |err| return std.posix.unexpectedErrno(err),
        }
    }
}

const SCM_RIGHTS: i32 = 1;

// linux only?
const cmsghdr = extern struct {
    len: usize, // TODO: This size is different on different OS'
    level: i32,
    type: i32,
};

inline fn cmsg_align(size: usize) usize {
    return std.mem.alignForward(usize, size, @sizeOf(usize));
}

inline fn cmsg_space(size: usize) usize {
    return cmsg_align(@sizeOf(cmsghdr)) + cmsg_align(size);
}

inline fn cmsg_len(size: usize) usize {
    return cmsg_align(@sizeOf(cmsghdr)) + size;
}
