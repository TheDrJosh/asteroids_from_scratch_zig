const std = @import("std");

const wayland_client = @import("wayland_client");

pub const Buffer = @import("Buffer.zig");

//TODO move to wayland_client
const SharedMemoryManager = @This();

wl_shm: *wayland_client.protocols.wayland.WlShm,
prng: std.Random.DefaultPrng,

pub fn init(registry: *wayland_client.Registry) !SharedMemoryManager {
    const wl_shm = try registry.bind(wayland_client.protocols.wayland.WlShm) orelse @panic("no global wl_shm");

    const prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    return .{
        .wl_shm = wl_shm,
        .prng = prng,
    };
}

pub fn deinit(self: *const SharedMemoryManager) void {
    self.wl_shm.deinit();
}

pub fn createBuffer(
    self: *SharedMemoryManager,
    size: u32,
) !Buffer {
    const fd = try self.allocateShmFile(size);
    defer std.posix.close(fd);

    const data = try std.posix.mmap(
        null,
        size,
        std.posix.PROT.READ | std.posix.PROT.WRITE,
        std.posix.MAP{
            .TYPE = .SHARED,
        },
        fd,
        0,
    );
    errdefer std.posix.munmap(data);

    const pool = try self.wl_shm.createPool(fd, @intCast(size));
    errdefer pool.deinit();

    return .{
        .data = data,
        .pool = pool,
    };
}

fn createShmFile(self: *SharedMemoryManager) !std.posix.fd_t {
    const random = self.prng.random();
    for (0..100) |_| {
        const rand = random.int(u32);
        var buff = [1]u8{0} ** 17;
        const name = try std.fmt.bufPrintZ(&buff, "/wl_shm-{X:0>8}", .{rand});

        // std.debug.print("name: {s}\n", .{name});

        const fd = std.c.shm_open(name.ptr, @bitCast(std.c.O{
            .ACCMODE = .RDWR,
            .CREAT = true,
            .EXCL = true,
        }), 600);

        switch (std.posix.errno(fd)) {
            .SUCCESS => {},
            .EXIST => continue,
            else => return error.failed_to_find_name,
        }

        //TODO error handling?
        _ = std.c.shm_unlink(name.ptr);

        return fd;
    }
    return error.failed_to_find_name;
}

fn allocateShmFile(self: *SharedMemoryManager, size: usize) !std.posix.fd_t {
    const fd = try self.createShmFile();
    errdefer std.posix.close(fd);

    try std.posix.ftruncate(fd, @intCast(size));

    return fd;
}
