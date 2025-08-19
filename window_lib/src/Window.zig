const std = @import("std");

const wayland_client = @import("wayland_client");

const Context = @import("Context.zig");
const FrameManager = @import("FrameManager.zig");

const Window = @This();

context: *Context,

surface: wayland_client.protocols.wayland.WlSurface,
xdg_surface: wayland_client.protocols.xdg_shell.XdgSurface,
toplevel_surface: wayland_client.protocols.xdg_shell.XdgToplevel,

toplevel_decoration: ?wayland_client.protocols.xdg_decoration_unstable_v1.ZxdgToplevelDecorationV1,

frame_callback: ?wayland_client.protocols.wayland.WlCallback,

current_size: ?Size,
has_decorations: bool,
force_client_decorations: bool,
should_close: bool,

pub const Config = struct {
    title: []const u8,
    app_id: ?[]const u8 = null,
    start_size: ?Size = null,
    max_size: ?Size = null,
    min_size: ?Size = null,
    decorations: bool = true,
    force_client_decorations: bool = false,
};

pub const Size = struct {
    width: u32,
    height: u32,
};

pub fn init(window: *Window, context: *Context, config: Config) !void {
    window.* = .{
        .frame_callback = null,
        .should_close = false,
        .current_size = config.start_size,
        .has_decorations = config.decorations,
        .force_client_decorations = config.force_client_decorations,
        .context = context,
        .surface = undefined,
        .xdg_surface = undefined,
        .toplevel_surface = undefined,
        .toplevel_decoration = undefined,
    };

    try context.compositor.createSurface(&window.surface);

    try context.wm_base.getXdgSurface(&window.xdg_surface, &window.surface);

    try window.xdg_surface.getToplevel(&window.toplevel_surface);

    try window.toplevel_surface.setTitle(config.title);

    if (config.max_size) |max_size| {
        try window.toplevel_surface.setMaxSize(@intCast(max_size.width), @intCast(max_size.height));
    }
    if (config.min_size) |min_size| {
        try window.toplevel_surface.setMinSize(@intCast(min_size.width), @intCast(min_size.height));
    }
    if (config.app_id) |app_id| {
        try window.toplevel_surface.setAppId(app_id);
    }

    var toplevel_decoration_manager: ?wayland_client.protocols.xdg_decoration_unstable_v1.ZxdgDecorationManagerV1 = undefined;
    context.registry.bind(
        wayland_client.protocols.xdg_decoration_unstable_v1.ZxdgDecorationManagerV1,
        &toplevel_decoration_manager.?,
    ) catch |e| if (e == error.global_not_found) {
        toplevel_decoration_manager = null;
    } else return e;

    if (toplevel_decoration_manager) |*manager| {
        defer manager.deinit();

        try manager.getToplevelDecoration(&window.toplevel_decoration.?, &window.toplevel_surface);

        if (config.decorations) {
            if (config.force_client_decorations) {
                try window.toplevel_decoration.?.setMode(.client_side);
            } else {
                try window.toplevel_decoration.?.setMode(.server_side);
            }
        }
    } else {
        window.toplevel_decoration = null;
    }

    try window.surface.commit();
}

pub fn deinit(self: *Window) void {
    if (self.frame_callback) |*c| {
        c.deinit();
    }
    if (self.toplevel_decoration) |*decor| {
        decor.deinit();
    }
    self.toplevel_surface.deinit();
    self.xdg_surface.deinit();
    self.surface.deinit();
}

pub fn close(self: *Window) void {
    self.should_close = true;
}

pub fn shouldClose(self: *Window) !bool {
    if (try self.toplevel_surface.nextClose()) {
        self.close();
    }
    return self.should_close;
}

pub fn pollEvents(self: *const Window) !void {
    _ = self;
}

pub fn presentFrame(self: *Window, frame: anytype) !void { //FrameManager.Frame(FrameManager.PixelXrgb8888)

    if (self.frame_callback) |*c| {
        while (try c.nextDone() == null) {}
    }

    try self.surface.attach(&(try frame.getBuffer()).wl_buffer, 0, 0);
    try self.surface.damage(0, 0, @intCast(frame.width), @intCast(frame.height()));
    if (self.frame_callback) |*c| {
        c.deinit();
    }
    self.frame_callback = undefined;
    try self.surface.frame(&self.frame_callback.?);

    try self.surface.commit();

    while (try self.context.wm_base.nextPing()) |ping| {
        std.debug.print("pong\n", .{});
        try self.context.wm_base.pong(ping.serial);
    }
}
