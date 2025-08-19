const std = @import("std");

const wayland_client = @import("wayland_client");

const FrameManager = @import("FrameManager.zig");

const Context = @This();

runtime: wayland_client.Runtime,

display: wayland_client.Display,
registry: wayland_client.Registry,

compositor: wayland_client.protocols.wayland.WlCompositor,
wm_base: wayland_client.protocols.xdg_shell.XdgWmBase,

frame_manager: FrameManager,

allocator: std.mem.Allocator,

pub fn init(context: *Context, allocator: std.mem.Allocator) !void {
    context.runtime = try wayland_client.Runtime.init(allocator);
    errdefer context.runtime.deinit();

    _ = try std.Thread.spawn(.{}, wayland_client.Runtime.pullEvents, .{&context.runtime});

    try context.runtime.display(&context.display);

    try context.display.getRegistry(&context.registry);
    errdefer context.registry.deinit();

    try context.registry.bind(wayland_client.protocols.wayland.WlCompositor, &context.compositor);
    try context.registry.bind(wayland_client.protocols.xdg_shell.XdgWmBase, &context.wm_base);
    errdefer context.wm_base.deinit();

    try FrameManager.init(&context.frame_manager, allocator, &context.registry);
    errdefer context.frame_manager.deinit();
}

pub fn deinit(self: *Context) void {
    self.frame_manager.deinit();
    self.compositor.deinit();
    self.wm_base.deinit();
    self.registry.deinit();
    self.display.deinit();
    self.runtime.deinit();
}

pub fn keepAlive(self: *Context) !void {
    while (try self.wm_base.nextPing()) |ping| {
        try self.wm_base.pong(ping.serial);
    }
}
