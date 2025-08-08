const std = @import("std");

const wayland_client = @import("wayland_client");
const WaylandRuntime = wayland_client.WaylandRuntime;
const wayland_types = wayland_client.types;

const protocols = wayland_client.protocols;

const GlobalManager = struct {
    registry: protocols.wayland.WlRegistry,
    globals: std.ArrayList(GlobalInfo),

    const GlobalInfo = struct {
        name: u32,
        interface: wayland_types.String,
        version: u32,
    };

    pub fn init(registry: protocols.wayland.WlRegistry, allocator: std.mem.Allocator) GlobalManager {
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
        while (try self.registry.nextGlobal()) |global| {
            try self.globals.append(.{
                .name = global.name,
                .version = global.version,
                .interface = global.interface,
            });
            // std.debug.print("Global(name: {}, interface: {s}, version: {})\n", .{ global.name, global.interface.data(), global.version });
        }

        while (try self.registry.nextGlobalRemove()) |global| {
            for (0..self.globals.items.len) |i| {
                if (self.globals.items[i].name == global.name) {
                    self.globals.swapRemove(i).interface.deinit();
                    break;
                }
            }
        }

        for (0..self.globals.items.len) |i| {
            if (std.mem.eql(u8, self.globals.items[i].interface.data(), T.interface)) {
                return (try self.registry.bind(self.globals.items[i].name, T, self.globals.items[i].version));
            }
        }
        return null;
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
    while (retries > 0 and (std.c._errno().* == @intFromEnum(std.c.E.EXIST) or retries == 100)) {
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

    var ret: c_int = std.c.ftruncate(fd, @intCast(size));
    while (ret < 0 and std.c._errno().* == @intFromEnum(std.c.E.INTR)) {
        ret = std.c.ftruncate(fd, @intCast(size));
    }
    if (ret < 0) {
        std.posix.close(fd);
        return error.failed;
    }
    return fd;
}

const width = 800;
const height = 600;

fn drawFrame(wl_shm: protocols.wayland.WlShm) !protocols.wayland.WlBuffer {
    const stride = width * 4;
    const size = height * stride;

    const fd = try allocateShmFile(size);
    defer std.posix.close(fd);
    const data = try std.posix.mmap(null, size, std.posix.PROT.READ | std.posix.PROT.WRITE, std.posix.MAP{ .TYPE = .SHARED }, fd, 0);
    defer std.posix.munmap(data);
    const pool = try wl_shm.createPool(fd, size);
    defer pool.destroy() catch unreachable;

    const buffer = try pool.createBuffer(0, width, height, stride, protocols.wayland.WlShm.Format.xrgb8888);

    const pixels = std.mem.bytesAsSlice(u32, data);

    for (0..height) |y| {
        for (0..width) |x| {
            if ((x + y / 8 * 8) % 16 < 8) {
                pixels[y * width + x] = 0xFFFFFFF;
            } else {
                pixels[y * width + x] = 0xFF000000;
            }
        }
    }

    return buffer;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var runtime = try WaylandRuntime.init(allocator);
    defer runtime.deinit();

    const display = runtime.display();

    const registry = (try display.getRegistry());

    const sync_callback = (try display.sync());

    while (try sync_callback.nextDone() == null) {}

    var global_manager = GlobalManager.init(registry, allocator);
    defer global_manager.deinit();

    const compositor = try global_manager.bind(protocols.wayland.WlCompositor) orelse unreachable;

    const surface = (try compositor.createSurface());

    const wl_shm = try global_manager.bind(protocols.wayland.WlShm) orelse unreachable;

    const wm_base = try global_manager.bind(protocols.xdg_shell.XdgWmBase) orelse unreachable;

    const xdg_surface = (try wm_base.getXdgSurface(surface));

    const toplevel_surface = (try xdg_surface.getToplevel());

    try toplevel_surface.setTitle("test");
    try surface.commit();

    const decoration_manager = try global_manager.bind(protocols.xdg_decoration_unstable_v1.ZxdgDecorationManagerV1) orelse unreachable;
    defer decoration_manager.destroy() catch unreachable;

    const decoration = (try decoration_manager.getToplevelDecoration(toplevel_surface));

    try decoration.setMode(protocols.xdg_decoration_unstable_v1.ZxdgToplevelDecorationV1.Mode.server_side);

    const seat = try global_manager.bind(protocols.wayland.WlSeat) orelse undefined;

    const keyboard = try seat.getKeyboard();

    const bell = try global_manager.bind(protocols.xdg_system_bell_v1.XdgSystemBellV1) orelse undefined;

    while (true) {
        if (try xdg_surface.nextConfigure()) |conf| {
            try xdg_surface.ackConfigure(conf.serial);
            const buffer = try drawFrame(wl_shm);

            try surface.attach(buffer, 0, 0);
            try surface.commit();
        }

        if (try wm_base.nextPing()) |ping| {
            try wm_base.pong(ping.serial);
        }

        while (try keyboard.nextKey()) |key| {
            std.debug.print("{any}\n", .{key});
            if (key.state == .pressed) {
                try bell.ring(surface);
            }
        }

        if (try toplevel_surface.nextClose()) {
            break;
        }
    }
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
