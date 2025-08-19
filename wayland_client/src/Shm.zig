const std = @import("std");

const Runtime = @import("Runtime.zig");
const types = @import("types.zig");
const protocols = @import("protocols");
const ShmPool = @import("ShmPool.zig");

pub const Format = protocols.wayland.WlShm.Format;

const Shm = @This();

object_id: types.ObjectId,
runtime: *Runtime,
formats: std.EnumSet(Format),
formats_mutex: std.Thread.Mutex,

pub const interface = "wl_shm";
pub const version = 2;

pub fn init(object_id: types.ObjectId, runtime: *Runtime) !*Shm {
    const object = try runtime.allocator.create(Shm);
    object.* = .{
        .object_id = object_id,
        .runtime = runtime,
        .formats = .initEmpty(),
        .formats_mutex = .{},
    };
    try runtime.registerObject(object);
    return object;
}

pub fn deinit(self: *Shm) void {
    self.runtime.unregisterObject(self.object_id);
    self.runtime.sendRequest(self.object_id, 1, .{}) catch unreachable;
    self.runtime.allocator.destroy(self);
}

pub fn supportsFormat(self: *Shm, format: Format) bool {
    self.formats_mutex.lock();
    defer self.formats_mutex.unlock();
    return self.formats.contains(format);
}

pub fn createPool(self: *Shm, name: [:0]u8, size: u32) !*ShmPool {
    const pool_id = self.runtime.getId();

    const fd = std.fs.File{
        .handle = try allocateShmFile(name, size),
    };
    errdefer fd.close();

    const data = try std.posix.mmap(
        null,
        size,
        std.posix.PROT.READ | std.posix.PROT.WRITE,
        std.posix.MAP{
            .TYPE = .SHARED,
        },
        fd.handle,
        0,
    );
    errdefer std.posix.munmap(data);

    const pool = try ShmPool.init(pool_id, self.runtime, fd, data);
    errdefer pool.deinit();

    try self.runtime.sendRequest(
        self.object_id,
        0,
        .{
            pool_id,
            fd,
            size,
        },
    );

    return pool;
}

fn createShmFile(name: [:0]u8) !std.posix.fd_t {
    const fd = std.c.shm_open(name.ptr, @bitCast(std.c.O{
        .ACCMODE = .RDWR,
        .CREAT = true,
        .EXCL = true,
    }), 600);

    switch (std.posix.errno(fd)) {
        .SUCCESS => {},
        else => return error.failed_to_create_shm,
    }

    switch (std.posix.errno(std.c.shm_unlink(name.ptr))) {
        .SUCCESS => {},
        else => return error.failed_to_unlink,
    }

    return fd;
}

fn allocateShmFile(name: [:0]u8, size: usize) !std.posix.fd_t {
    const fd = try createShmFile(name);
    errdefer std.posix.close(fd);

    try std.posix.ftruncate(fd, @intCast(size));

    return fd;
}

pub fn handleError(self: *Shm, code: u32, message: []const u8) void {
    std.debug.panic(
        "Wayland Error recived on WlShm(id: {}, code: {}, message: {s})",
        .{
            self.object_id,
            @as(protocols.wayland.WlShm.Error, @enumFromInt(code)),
            message,
        },
    );
}

pub fn handleEvent(self: *Shm, msg: Runtime.MessageStream.Message) void {
    switch (msg.info.opcode) {
        0 => {
            const format_event = msg.parse(protocols.wayland.WlShm.FormatEvent, self.runtime) catch @panic("failed to parse event args");
            self.formats_mutex.lock();
            defer self.formats_mutex.unlock();

            self.formats.insert(format_event.args.format);
        },
        else => {},
    }
}
