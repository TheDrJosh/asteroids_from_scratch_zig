const std = @import("std");
const posix = std.posix;
const linux = std.os.linux;
const c = std.c;
const net = std.net;
const mem = std.mem;
const print = std.debug.print;

fn CMSG_ALIGN(len: usize) usize {
    return (len + @sizeOf(usize) - 1) & ~@as(usize, (@sizeOf(usize) - 1));
}

fn CMSG_SPACE(len: usize) usize {
    return CMSG_ALIGN(len) + CMSG_ALIGN(@sizeOf(c.cmsghdr));
}

fn CMSG_LEN(len: usize) usize {
    return CMSG_ALIGN(@sizeOf(c.cmsghdr)) + len;
}

fn CMSG_FIRSTHDR(msg: *const linux.msghdr) ?*c.cmsghdr {
    if (msg.controllen >= @sizeOf(c.cmsghdr)) {
        return @as(?*c.cmsghdr, @ptrCast(@alignCast(msg.control)));
    }
    return null;
}

fn CMSG_NXTHDR(msg: *const linux.msghdr, cmsg: *const linux.cmsghdr) ?*linux.cmsghdr {
    const cmsg_ptr = @intFromPtr(cmsg);
    const control_ptr = @intFromPtr(msg.msg_control);
    const next_cmsg = cmsg_ptr + CMSG_ALIGN(cmsg.cmsg_len);

    if (next_cmsg + @sizeOf(linux.cmsghdr) > control_ptr + msg.msg_controllen) {
        return null;
    }

    return @as(*linux.cmsghdr, @ptrFromInt(next_cmsg));
}

fn CMSG_DATA(cmsg: *c.cmsghdr) [*]u8 {
    const cmsg_ptr = @intFromPtr(cmsg);
    const data_ptr = cmsg_ptr + CMSG_ALIGN(@sizeOf(c.cmsghdr));
    return @as([*]u8, @ptrFromInt(data_ptr));
}

const UnixSocketError = error{
    SocketCreationFailed,
    BindFailed,
    ListenFailed,
    AcceptFailed,
    ConnectFailed,
    SendFailed,
    ReceiveFailed,
    InvalidAddress,
};

/// Create a Unix domain socket
pub fn createUnixSocket() !posix.socket_t {
    return posix.socket(posix.AF.UNIX, posix.SOCK.STREAM, 0) catch |err| {
        print("Failed to create socket: {}\n", .{err});
        return UnixSocketError.SocketCreationFailed;
    };
}

/// Bind a Unix domain socket to a path
pub fn bindUnixSocket(sockfd: posix.socket_t, path: []const u8) !void {
    var addr = posix.sockaddr.un{
        .family = posix.AF.UNIX,
        .path = undefined,
    };

    if (path.len >= addr.path.len) {
        return UnixSocketError.InvalidAddress;
    }

    @memset(&addr.path, 0);
    @memcpy(addr.path[0..path.len], path);

    const addr_ptr = @as(*const posix.sockaddr, @ptrCast(&addr));
    const addr_len = @as(posix.socklen_t, @sizeOf(posix.sockaddr.un));

    posix.bind(sockfd, addr_ptr, addr_len) catch |err| {
        print("Failed to bind socket: {}\n", .{err});
        return UnixSocketError.BindFailed;
    };
}

/// Connect to a Unix domain socket
pub fn connectUnixSocket(sockfd: posix.socket_t, path: []const u8) !void {
    var addr = posix.sockaddr.un{
        .family = posix.AF.UNIX,
        .path = undefined,
    };

    if (path.len >= addr.path.len) {
        return UnixSocketError.InvalidAddress;
    }

    @memset(&addr.path, 0);
    @memcpy(addr.path[0..path.len], path);

    const addr_ptr = @as(*const posix.sockaddr, @ptrCast(&addr));
    const addr_len = @as(posix.socklen_t, @sizeOf(posix.sockaddr.un));

    posix.connect(sockfd, addr_ptr, addr_len) catch |err| {
        print("Failed to connect socket: {}\n", .{err});
        return UnixSocketError.ConnectFailed;
    };
}

/// Send data over a Unix domain socket
pub fn sendData(sockfd: posix.socket_t, data: []const u8) !usize {
    return posix.send(sockfd, data, 0) catch |err| {
        print("Failed to send data: {}\n", .{err});
        return UnixSocketError.SendFailed;
    };
}

/// Receive data from a Unix domain socket
pub fn receiveData(sockfd: posix.socket_t, buffer: []u8) !usize {
    return posix.recv(sockfd, buffer, 0) catch |err| {
        print("Failed to receive data: {}\n", .{err});
        return UnixSocketError.ReceiveFailed;
    };
}

/// Send multiple file descriptors over Unix domain socket using sendmsg
pub fn sendFileDescriptors(sockfd: posix.socket_t, fds: []const posix.fd_t, data: []const u8) !void {
    var iov = [_]posix.iovec_const{
        .{ .base = data.ptr, .len = data.len },
    };

    // Control message buffer for multiple file descriptors
    var cmsg_buf: [CMSG_SPACE(@sizeOf(posix.fd_t) * 32)]u8 align(@alignOf(c.cmsghdr)) = undefined;

    var msg = posix.msghdr{
        .name = null,
        .namelen = 0,
        .iov = @ptrCast(&iov),
        .iovlen = 1,
        .control = &cmsg_buf,
        .controllen = @intCast(CMSG_SPACE(@sizeOf(posix.fd_t) * fds.len)),
        .flags = 0,
    };

    // Set up control message
    const cmsg = CMSG_FIRSTHDR(&msg);
    if (cmsg) |cm| {
        cm.level = posix.SOL.SOCKET;
        cm.type = c.SCM.RIGHTS;
        cm.len = @intCast(CMSG_LEN(@sizeOf(posix.fd_t) * fds.len));

        // Copy all file descriptors to control message data
        const fd_array = @as([*]posix.fd_t, @ptrCast(@alignCast(CMSG_DATA(cm))));
        for (fds, 0..) |fd, i| {
            fd_array[i] = fd;
        }
    }

    _ = posix.sendmsg(sockfd, @ptrCast(&msg), 0) catch |err| {
        print("Failed to send file descriptors: {}\n", .{err});
        return UnixSocketError.SendFailed;
    };
}

/// Send single file descriptor (convenience wrapper)
pub fn sendFileDescriptor(sockfd: posix.socket_t, fd: posix.fd_t, data: []const u8) !void {
    const fds = [_]posix.fd_t{fd};
    return sendFileDescriptors(sockfd, &fds, data);
}

/// Receive multiple file descriptors from Unix domain socket using recvmsg
pub fn receiveFileDescriptors(sockfd: posix.socket_t, buffer: []u8, fd_buffer: []posix.fd_t) !struct { bytes_received: usize, fds_received: usize } {
    var iov = [_]posix.iovec{
        .{ .base = buffer.ptr, .len = buffer.len },
    };

    // Control message buffer for multiple file descriptors
    var cmsg_buf: [c.CMSG_SPACE(@sizeOf(posix.fd_t) * 32)]u8 align(@alignOf(c.cmsghdr)) = undefined;

    var msg = posix.msghdr{
        .name = null,
        .namelen = 0,
        .iov = &iov,
        .iovlen = 1,
        .control = &cmsg_buf,
        .controllen = cmsg_buf.len,
        .flags = 0,
    };

    const bytes_received = posix.recvmsg(sockfd, &msg, 0) catch |err| {
        print("Failed to receive message: {}\n", .{err});
        return UnixSocketError.ReceiveFailed;
    };

    var fds_received: usize = 0;

    // Check for control message with file descriptors
    var cmsg = c.CMSG_FIRSTHDR(&msg);
    while (cmsg) |cm| : (cmsg = c.CMSG_NXTHDR(&msg, cm)) {
        if (cm.cmsg_level == posix.SOL.SOCKET and cm.cmsg_type == c.SCM_RIGHTS) {
            const fd_data_len = cm.cmsg_len - c.CMSG_LEN(0);
            const num_fds = fd_data_len / @sizeOf(posix.fd_t);

            if (num_fds > fd_buffer.len) {
                print("Warning: received {} file descriptors but buffer only holds {}\n", .{ num_fds, fd_buffer.len });
            }

            const fd_array = @as([*]const posix.fd_t, @ptrCast(@alignCast(c.CMSG_DATA(cm))));
            const fds_to_copy = @min(num_fds, fd_buffer.len);

            for (0..fds_to_copy) |i| {
                fd_buffer[i] = fd_array[i];
            }

            fds_received = fds_to_copy;
            break;
        }
    }

    return .{
        .bytes_received = bytes_received,
        .fds_received = fds_received,
    };
}

/// Receive single file descriptor (convenience wrapper)
pub fn receiveFileDescriptor(sockfd: posix.socket_t, buffer: []u8) !struct { bytes_received: usize, fd: ?posix.fd_t } {
    var fd_buffer: [1]posix.fd_t = undefined;
    const result = try receiveFileDescriptors(sockfd, buffer, &fd_buffer);

    return .{
        .bytes_received = result.bytes_received,
        .fd = if (result.fds_received > 0) fd_buffer[0] else null,
    };
}

/// Example usage for server with multiple file descriptors
pub fn serverExample() !void {
    const socket_path = "/tmp/test_socket";

    // Remove existing socket file if it exists
    std.fs.cwd().deleteFile(socket_path) catch {};

    const sockfd = try createUnixSocket();
    defer posix.close(sockfd);

    try bindUnixSocket(sockfd, socket_path);

    try posix.listen(sockfd, 5);
    print("Server listening on {s}\n", .{socket_path});

    const client_fd = posix.accept(sockfd, null, null, 0) catch |err| {
        print("Failed to accept connection: {}\n", .{err});
        return UnixSocketError.AcceptFailed;
    };
    defer posix.close(client_fd);

    // Send multiple file descriptors
    const fds_to_send = [_]posix.fd_t{ posix.STDIN_FILENO, posix.STDOUT_FILENO, posix.STDERR_FILENO };
    const message = "Hello with multiple file descriptors!";
    try sendFileDescriptors(client_fd, &fds_to_send, message);

    print("Sent message and {} file descriptors\n", .{fds_to_send.len});
}

/// Example usage for client with multiple file descriptors
pub fn clientExample() !void {
    const socket_path = "/tmp/test_socket";

    const sockfd = try createUnixSocket();
    defer posix.close(sockfd);

    try connectUnixSocket(sockfd, socket_path);

    // Receive message and multiple file descriptors
    var buffer: [1024]u8 = undefined;
    var fd_buffer: [10]posix.fd_t = undefined;
    const result = try receiveFileDescriptors(sockfd, &buffer, &fd_buffer);

    print("Received {} bytes: {s}\n", .{ result.bytes_received, buffer[0..result.bytes_received] });
    print("Received {} file descriptors\n", .{result.fds_received});

    // Use the file descriptors as needed
    for (fd_buffer[0..result.fds_received], 0..) |fd, i| {
        print("File descriptor {}: {}\n", .{ i, fd });
        // Close the file descriptors when done
        // Note: Be careful with stdin/stdout/stderr in real applications
        // posix.close(fd);
    }
}
