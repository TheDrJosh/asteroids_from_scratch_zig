const std = @import("std");

const UnixStream = @This();

handle: std.posix.socket_t,

pub fn open(path: []const u8) !UnixStream {
    const handle = try std.posix.socket(
        std.posix.AF.UNIX,
        std.posix.SOCK.STREAM,
        0,
    );

    var addr = std.posix.sockaddr.un{
        .family = std.posix.AF.UNIX,
        .path = undefined,
    };

    if (path.len >= addr.path.len) {
        return error.invalid_path;
    }

    @memset(&addr.path, 0);
    @memcpy(addr.path[0..path.len], path);

    const addr_ptr = @as(*const std.posix.sockaddr, @ptrCast(&addr));
    const addr_len = @as(std.posix.socklen_t, @sizeOf(std.posix.sockaddr.un));

    try std.posix.connect(handle, addr_ptr, addr_len);

    return .{
        .handle = handle,
    };
}

pub fn close(self: UnixStream) void {
    std.posix.close(self.handle);
}

pub fn writer(self: UnixStream, buffer: []u8) Writer {
    return Writer.init(self.handle, buffer);
}

const MAX_BUFFERS = 8;

pub const Writer = struct {
    handle: std.posix.socket_t,
    err: ?std.posix.SendMsgError = null,

    interface: std.Io.Writer,

    pub fn init(handle: std.posix.socket_t, buffer: []u8) Writer {
        return Writer{
            .handle = handle,

            .interface = std.Io.Writer{
                .buffer = buffer,
                .end = 0,
                .vtable = &std.Io.Writer.VTable{
                    .drain = drain,
                    .sendFile = sendFile,
                },
            },
        };
    }

    fn addBuf(v: []std.posix.iovec_const, i: *@FieldType(std.posix.msghdr_const, "iovlen"), bytes: []const u8) void {
        // OS checks ptr addr before length so zero length vectors must be omitted.
        if (bytes.len == 0) return;
        if (v.len - i.* == 0) return;
        v[i.*] = .{ .base = bytes.ptr, .len = bytes.len };
        i.* += 1;
    }

    fn drain(io_w: *std.Io.Writer, data: []const []const u8, splat: usize) std.Io.Writer.Error!usize {
        const w: *Writer = @alignCast(@fieldParentPtr("interface", io_w));
        const buffered = io_w.buffered();

        var iovecs: [MAX_BUFFERS]std.posix.iovec_const = undefined;
        var msg: std.posix.msghdr_const = .{
            .name = null,
            .namelen = 0,
            .iov = &iovecs,
            .iovlen = 0,
            .control = null,
            .controllen = 0,
            .flags = 0,
        };
        addBuf(&iovecs, &msg.iovlen, buffered);
        for (data[0 .. data.len - 1]) |bytes| addBuf(&iovecs, &msg.iovlen, bytes);
        const pattern = data[data.len - 1];
        if (iovecs.len - msg.iovlen != 0) switch (splat) {
            0 => {},
            1 => addBuf(&iovecs, &msg.iovlen, pattern),
            else => switch (pattern.len) {
                0 => {},
                1 => {
                    const splat_buffer_candidate = io_w.buffer[io_w.end..];
                    var backup_buffer: [64]u8 = undefined;
                    const splat_buffer = if (splat_buffer_candidate.len >= backup_buffer.len)
                        splat_buffer_candidate
                    else
                        &backup_buffer;
                    const memset_len = @min(splat_buffer.len, splat);
                    const buf = splat_buffer[0..memset_len];
                    @memset(buf, pattern[0]);
                    addBuf(&iovecs, &msg.iovlen, buf);
                    var remaining_splat = splat - buf.len;
                    while (remaining_splat > splat_buffer.len and iovecs.len - msg.iovlen != 0) {
                        std.debug.assert(buf.len == splat_buffer.len);
                        addBuf(&iovecs, &msg.iovlen, splat_buffer);
                        remaining_splat -= splat_buffer.len;
                    }
                    addBuf(&iovecs, &msg.iovlen, splat_buffer[0..remaining_splat]);
                },
                else => for (0..@min(splat, iovecs.len - msg.iovlen)) |_| {
                    addBuf(&iovecs, &msg.iovlen, pattern);
                },
            },
        };
        const flags = std.posix.MSG.NOSIGNAL;
        return io_w.consume(std.posix.sendmsg(w.handle, &msg, flags) catch |err| {
            w.err = err;
            return error.WriteFailed;
        });
    }

    fn sendFile(
        w: *std.Io.Writer,
        file_reader: *std.fs.File.Reader,
        /// Maximum amount of bytes to read from the file. Implementations may
        /// assume that the file size does not exceed this amount. Data from
        /// `buffer` does not count towards this limit.
        limit: std.Io.Limit,
    ) std.Io.Writer.FileError!usize {
        if (limit != .unlimited) {
            return error.Unimplemented;
        }
        const self: *Writer = @alignCast(@fieldParentPtr("interface", w));

        const data = w.buffered();

        if (data.len == 0) {
            return error.WriteFailed;
        }

        var cmsgbuf: [cmsg_space(@sizeOf(std.posix.fd_t) * 1)]u8 align(@alignOf(cmsghdr)) = undefined;

        var cmsg: *cmsghdr = @ptrCast(&cmsgbuf);

        cmsg.level = std.posix.SOL.SOCKET;
        cmsg.type = SCM_RIGHTS;
        cmsg.len = @intCast(cmsg_len(@sizeOf(std.posix.fd_t) * 1));

        var fds = std.mem.bytesAsSlice(std.posix.fd_t, cmsgbuf[@sizeOf(cmsghdr)..]);
        fds[0] = file_reader.file.handle;

        const n = std.posix.sendmsg(self.handle, &std.posix.msghdr_const{
            .name = null,
            .namelen = 0,
            .iov = &[1]std.posix.iovec_const{std.posix.iovec_const{
                .base = data.ptr,
                .len = data.len,
            }},
            .iovlen = 1,
            .control = &cmsgbuf,
            .controllen = @intCast(cmsgbuf.len),
            .flags = 0,
        }, 0) catch |e| {
            self.err = e;
            return error.WriteFailed;
        };
        return w.consume(n);
    }
};

pub fn reader(self: UnixStream, buffer: []u8, fd_buffer: []align(@alignOf(std.posix.fd_t)) u8) Reader {
    return Reader.init(self.handle, buffer, fd_buffer);
}

pub const Reader = struct {
    handle: std.posix.socket_t,
    fd_buffer: ?[]std.posix.fd_t,
    cmsgbuf: []align(@alignOf(std.posix.fd_t)) u8,
    err: ?RecvMsgError = null,

    interface: std.Io.Reader,

    pub fn init(handle: std.posix.socket_t, buffer: []u8, fd_buffer: []align(@alignOf(std.posix.fd_t)) u8) Reader {
        std.debug.assert(std.mem.isAligned(@intFromPtr(fd_buffer.ptr), @alignOf(cmsghdr)));

        return Reader{
            .handle = handle,
            .fd_buffer = null,
            .cmsgbuf = fd_buffer,
            .interface = std.Io.Reader{
                .buffer = buffer,
                .seek = 0,
                .end = 0,
                .vtable = &std.Io.Reader.VTable{
                    .stream = stream,
                    .readVec = readVec,
                },
            },
        };
    }

    fn stream(r: *std.Io.Reader, w: *std.Io.Writer, limit: std.Io.Limit) std.Io.Reader.StreamError!usize {
        const dest = limit.slice(try w.writableSliceGreedy(1));

        var data = [1][]u8{dest};

        const n = try readVec(r, &data);
        r.seek += n;

        return n;
    }

    fn addBuf(v: []std.posix.iovec, i: *@FieldType(std.posix.msghdr, "iovlen"), bytes: []u8) void {
        // OS checks ptr addr before length so zero length vectors must be omitted.
        if (bytes.len == 0) return;
        if (v.len - i.* == 0) return;
        v[i.*] = .{ .base = bytes.ptr, .len = bytes.len };
        i.* += 1;
    }

    fn readVec(r: *std.Io.Reader, data: [][]u8) std.Io.Reader.Error!usize {
        const self: *Reader = @alignCast(@fieldParentPtr("interface", r));

        var iov: [MAX_BUFFERS]std.posix.iovec = undefined;

        const max_fds = maxFds(self.cmsgbuf.len);

        var msg = std.posix.msghdr{
            .name = null,
            .namelen = 0,
            .iov = &iov,
            .iovlen = 0,
            .control = self.cmsgbuf.ptr,
            .controllen = cmsg_space(@sizeOf(std.posix.fd_t) * max_fds),
            .flags = 0,
        };

        var modifing_buffer = false;

        if (data.len == 1 and data[0].len == 0) {
            addBuf(&iov, &msg.iovlen, r.buffer[r.end..]);
            modifing_buffer = true;
        } else {
            for (0..data.len) |i| {
                addBuf(&iov, &msg.iovlen, data[i]);
            }
        }

        if (msg.iovlen == 0) {
            return 0;
        }

        const n = recvmsg(self.handle, &msg, 0) catch |e| {
            if (e == RecvMsgError.WouldBlock) {
                return 0;
            }

            self.err = e;
            return error.ReadFailed;
        };

        if (modifing_buffer) {
            r.end += n;
        }

        if (msg.control) |ctl| {
            const cmsg: *const cmsghdr = @ptrCast(&ctl);
            if (cmsg.level == std.posix.SOL.SOCKET and cmsg.type == SCM_RIGHTS) {
                const num_fds = (cmsg.len - cmsg_len(0)) / @sizeOf(std.posix.fd_t);

                self.fd_buffer = std.mem.bytesAsSlice(std.posix.fd_t, self.cmsgbuf[@sizeOf(cmsghdr)..cmsg_space(@sizeOf(std.posix.fd_t) * num_fds)]);
            }
        } else {
            self.fd_buffer = null;
        }

        return n;
    }

    fn maxFds(n: usize) usize {
        return std.mem.alignBackward(usize, n - cmsg_align(@sizeOf(cmsghdr)), @sizeOf(usize)) / @sizeOf(std.posix.fd_t);
    }

    test "correct fd count from cmsghdr buffer size" {
        // @compileLog(comptime (cmsg_space(@sizeOf(std.posix.fd_t) * 2)));
        for (cmsg_space(@sizeOf(std.posix.fd_t) * 0)..16384) |i| {
            const ac = maxFds(i);

            var ex: usize = 0;

            for (0..16384) |j| {
                if (cmsg_space(@sizeOf(std.posix.fd_t) * j) <= i) {
                    ex = j;
                } else {
                    break;
                }
            }

            // std.debug.print("size: {}\n", .{i});

            try std.testing.expectEqual(ex, ac);
        }
    }
};

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

test {
    @import("std").testing.refAllDecls(@This());
}
