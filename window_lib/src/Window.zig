const std = @import("std");

const wayland_client = @import("wayland_client");

const Context = @import("Context.zig");
const Frame = @import("Frame.zig");

const Window = @This();

surface: *wayland_client.protocols.wayland.WlSurface,
xdg_surface: *wayland_client.protocols.xdg_shell.XdgSurface,
toplevel_surface: *wayland_client.protocols.xdg_shell.XdgToplevel,

toplevel_decoration: ?*wayland_client.protocols.xdg_decoration_unstable_v1.ZxdgToplevelDecorationV1,

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

pub fn init(context: *Context, config: Config) !Window {
    const surface = try context.compositor.createSurface();

    const xdg_surface = try context.wm_base.getXdgSurface(surface);

    const toplevel_surface = try xdg_surface.getToplevel();

    try toplevel_surface.setTitle(config.title);

    if (config.max_size) |max_size| {
        try toplevel_surface.setMaxSize(@intCast(max_size.width), @intCast(max_size.height));
    }
    if (config.min_size) |min_size| {
        try toplevel_surface.setMinSize(@intCast(min_size.width), @intCast(min_size.height));
    }
    if (config.app_id) |app_id| {
        try toplevel_surface.setAppId(app_id);
    }

    const toplevel_decoration = if (try context.registry.bind(
        wayland_client.protocols.xdg_decoration_unstable_v1.ZxdgDecorationManagerV1,
    )) |manager| blk: {
        defer manager.deinit();

        const decor = try manager.getToplevelDecoration(toplevel_surface);

        if (config.decorations) {
            if (config.force_client_decorations) {
                try decor.setMode(.client_side);
            } else {
                try decor.setMode(.server_side);
            }
        }

        break :blk decor;
    } else null;

    try surface.commit();

    return .{
        .surface = surface,
        .xdg_surface = xdg_surface,
        .toplevel_surface = toplevel_surface,
        .current_size = config.start_size,
        .has_decorations = config.decorations,
        .force_client_decorations = config.force_client_decorations,
        .toplevel_decoration = toplevel_decoration,
        .should_close = false,
    };
}

pub fn deinit(self: *const Window) void {
    if (self.toplevel_decoration) |decor| {
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

pub fn presentFrame(self: *const Window, frame: Frame) !void {
    _ = frame;
    while (try self.wm_base.nextPing()) |ping| {
        try self.wm_base.pong(ping.serial);
    }
}
