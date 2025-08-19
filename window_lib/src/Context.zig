const std = @import("std");

const wayland_client = @import("wayland_client");

const FrameManager = @import("FrameManager.zig");

const Context = @This();

runtime: *wayland_client.Runtime,

display: *wayland_client.Display,
registry: *wayland_client.Registry,

compositor: *wayland_client.protocols.wayland.WlCompositor,
wm_base: *wayland_client.protocols.xdg_shell.XdgWmBase,

frame_manager: FrameManager,

allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) !Context {
    var runtime = try allocator.create(wayland_client.Runtime);
    errdefer allocator.destroy(runtime);
    runtime.* = try wayland_client.Runtime.init(allocator);
    errdefer runtime.deinit();

    _ = try std.Thread.spawn(.{}, wayland_client.Runtime.pullEvents, .{runtime});

    const display = try runtime.display();

    var registry = try display.getRegistry();
    errdefer registry.deinit();

    const compositor = try registry.bind(wayland_client.protocols.wayland.WlCompositor) orelse @panic("wl_compositor not found in globals");
    const wm_base = try registry.bind(wayland_client.protocols.xdg_shell.XdgWmBase) orelse @panic("xdg_wm_base not found in globals");
    errdefer wm_base.deinit();

    const frame_manager = try FrameManager.init(allocator, registry);
    errdefer frame_manager.deinit();

    return .{
        .runtime = runtime,

        .display = display,
        .registry = registry,

        .compositor = compositor,
        .wm_base = wm_base,

        .frame_manager = frame_manager,

        .allocator = allocator,
    };
}

pub fn deinit(self: *Context) void {
    self.frame_manager.deinit();
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
