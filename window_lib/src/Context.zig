const std = @import("std");

const wayland_client = @import("wayland_client");

pub const SharedMemoryManager = @import("SharedMemoryManager.zig");

const Context = @This();

runtime: *wayland_client.WaylandRuntime,

display: *wayland_client.Display,
registry: *wayland_client.Registry,
shared_memory_manager: SharedMemoryManager,

compositor: *wayland_client.protocols.wayland.WlCompositor,
wm_base: *wayland_client.protocols.xdg_shell.XdgWmBase,

allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) !Context {
    var runtime = try allocator.create(wayland_client.WaylandRuntime);
    errdefer allocator.destroy(runtime);
    runtime.* = try wayland_client.WaylandRuntime.init(allocator);
    errdefer runtime.deinit();

    _ = try std.Thread.spawn(.{}, wayland_client.WaylandRuntime.pullEvents, .{runtime});

    const display = try runtime.display();

    var registry = try display.getRegistry();
    errdefer registry.deinit();

    const shared_memory_manager = try SharedMemoryManager.init(registry);
    errdefer shared_memory_manager.deinit();

    const compositor = try registry.bind(wayland_client.protocols.wayland.WlCompositor) orelse @panic("wl_compositor not found in globals");
    const wm_base = try registry.bind(wayland_client.protocols.xdg_shell.XdgWmBase) orelse @panic("xdg_wm_base not found in globals");
    errdefer wm_base.deinit();

    return .{
        .runtime = runtime,

        .display = display,
        .registry = registry,
        .shared_memory_manager = shared_memory_manager,

        .compositor = compositor,
        .wm_base = wm_base,

        .allocator = allocator,
    };
}

pub fn deinit(self: *const Context) void {
    self.shared_memory_manager.deinit();
    self.compositor.deinit();
    self.wm_base.deinit();
    self.registry.deinit();
    self.display.deinit();
    self.runtime.deinit();
    self.allocator.destroy(self.runtime);
}

pub fn keepAlive(self: *Context) !void {
    while (try self.wm_base.nextPing()) |ping| {
        try self.wm_base.pong(ping.serial);
    }
}
