const std = @import("std");
const WaylandRuntime = @import("wayland/WaylandRuntime.zig");
const wayland_types = @import("wayland/wayland_types.zig");
const wayland_protocol = @import("wayland/protocols/wayland.zig");

const GlobalManager = struct {
    registry: wayland_protocol.wl_registry,
    globals: std.ArrayList(GlobalInfo),

    const GlobalInfo = struct {
        name: u32,
        interface: std.ArrayList(u8),
        version: u32,
    };

    pub fn init(registry: wayland_protocol.wl_registry, allocator: std.mem.Allocator) GlobalManager {
        return .{
            .registry = registry,
            .globals = std.ArrayList(GlobalInfo).init(allocator),
        };
    }

    pub fn deinit(self: *const GlobalManager) void {
        for (self.globals.items) |g| {
            g.interface.deinit();
        }
        self.globals.deinit();
    }

    pub fn bind(self: *GlobalManager, T: type) !?T {
        while (try self.registry.next_global()) |global| {
            try self.globals.append(.{
                .name = global.name,
                .version = global.version,
                .interface = global.interface.data,
            });
            std.debug.print("Global(name: {}, interface: {s}, version: {})\n", .{ global.name, global.interface.data.items, global.version });
        }

        while (try self.registry.next_global_remove()) |global| {
            for (0..self.globals.items.len) |i| {
                if (self.globals.items[i].name == global.name) {
                    self.globals.swapRemove(i).interface.deinit();
                    break;
                }
            }
        }

        const name = for (0..self.globals.items.len) |i| {
            if (std.mem.eql(u8, self.globals.items[i].interface.items, T.interface)) {
                if (self.globals.items[i].version < T.version) {
                    std.debug.print("Warnning global {s} version is less than expected. got version {} expected {}\n", .{ self.globals.items[i].interface.items, self.globals.items[i].version, T.version });
                }
                break self.globals.items[i].name;
            }
        } else return null;

        return (try self.registry.bind(name, T)).id;
    }
};

fn randname() ![6]u8 {
    var buf = [1]u8{0} ** 6;

    const ts = try std.posix.clock_gettime(.REALTIME);
    var r = ts.nsec;

    for (0..buf.len) |i| {
        buf[i] = 'A' + @as(u8, @intCast(r & 15)) + @as(u8, @intCast(r & 16)) * 2;
        r >>= 5;
    }

    return buf;
}

fn createShmFile() !std.posix.fd_t {
    var retries: u8 = 100;
    while (retries > 0 and std.c._errno().* == @intFromEnum(std.c.E.EXIST)) {
        var name = [1:0]u8{0} ** ("/wl_shm-XXXXXX".len);
        _ = try std.fmt.bufPrint(&name, "/wl_shm-{s}", .{try randname()});
        retries -= 1;
        const fd = std.c.shm_open(&name, @bitCast(std.c.O{
            .ACCMODE = .RDWR,
            .CREAT = true,
            .EXCL = true,
        }), 600);
        if (fd >= 0) {
            _ = std.c.shm_unlink(&name);
            return fd;
        }
    }

    return error.failed_to_find_name;
}

fn allocateShmFile(size: usize) !std.posix.fd_t {
    const fd = try createShmFile();

    var ret: c_int = 0;
    while (ret < 0 and std.c._errno().* == @intFromEnum(std.c.E.INTR)) {
        ret = std.c.ftruncate(fd, @intCast(size));
    }
    if (ret < 0) {
        std.posix.close(fd);
        return error.failed;
    }
    return fd;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var runtime = try WaylandRuntime.init(allocator);
    defer runtime.deinit();

    const display = runtime.display();

    const registry = (try display.get_registry()).registry;

    std.Thread.sleep(1_000_000_000);

    var global_manager = GlobalManager.init(registry, allocator);
    defer global_manager.deinit();

    const compositor = try global_manager.bind(wayland_protocol.wl_compositor) orelse unreachable;

    const surface = (try compositor.create_surface()).id;

    const wl_shm = try global_manager.bind(wayland_protocol.wl_shm) orelse unreachable;

    const width = 1920;
    const height = 1080;

    const stride = width * 4;
    const shm_pool_size = height * stride * 2;

    const fd = try allocateShmFile(shm_pool_size);
    const pool_data = try std.posix.mmap(null, shm_pool_size, std.posix.PROT.READ | std.posix.PROT.WRITE, std.posix.MAP{ .TYPE = .SHARED }, fd, 0);
    const pool = (try wl_shm.create_pool(wayland_types.Fd{.fd = fd}, shm_pool_size)).id;

    const index = 0;
    const offset = height * stride * index;
    const buffer = (try pool.create_buffer(offset, width, height, stride, @intFromEnum(wayland_protocol.wl_shm.enums.format.xrgb8888))).id;

    const pixels = std.mem.bytesAsSlice(u32, pool_data[offset..(height * stride)]);
    for (0..height) |y| {
        for (0..width) |x| {
            if ((x + y / 8 * 8) % 16 < 8) {
                pixels[y * width + x] = 0xFF666666;
            } else {
                pixels[y * width + x] = 0xFFEEEEEE;
            }
        }
    }

    try surface.attach(buffer.object_id, 0, 0);
    try surface.damage(0, 0, std.math.maxInt(i32), std.math.maxInt(i32));
    try surface.commit();
}

test "callback sync" {
    var runtime = try WaylandRuntime.init(std.testing.allocator);
    defer runtime.deinit();

    const display = runtime.display();

    const callback = (try display.sync()).callback;

    std.Thread.sleep(1_000_000_000);

    const ret = try callback.next_done();

    try std.testing.expect(ret != null);
}
