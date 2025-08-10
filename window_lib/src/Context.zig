const std = @import("std");

const wayland_client = @import("wayland_client");

const GlobalsManager = @import("GlobalsManager.zig");
pub const SharedMemoryManager = @import("SharedMemoryManager.zig");

const Context = @This();

runtime: *wayland_client.WaylandRuntime,

globals_manager: GlobalsManager,
shared_memory_manager: SharedMemoryManager,

compositor: wayland_client.protocols.wayland.WlCompositor,
wm_base: wayland_client.protocols.xdg_shell.XdgWmBase,

allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) !Context {
    var runtime = try allocator.create(wayland_client.WaylandRuntime);
    runtime.* = try wayland_client.WaylandRuntime.init(allocator);
    errdefer runtime.deinit();

    var globals_manager = try GlobalsManager.init(
        runtime,
        allocator,
    );
    errdefer globals_manager.deinit();

    const shared_memory_manager = try SharedMemoryManager.init(&globals_manager);
    errdefer shared_memory_manager.deinit();

    const compositor = try globals_manager.bind(wayland_client.protocols.wayland.WlCompositor) orelse @panic("wl_compositor not found in globals");
    const wm_base = try globals_manager.bind(wayland_client.protocols.xdg_shell.XdgWmBase) orelse @panic("xdg_wm_base not found in globals");
    errdefer wm_base.deinit();

    return .{
        .runtime = runtime,

        .globals_manager = globals_manager,
        .shared_memory_manager = shared_memory_manager,

        .compositor = compositor,
        .wm_base = wm_base,

        .allocator = allocator,
    };
}

pub fn deinit(self: *const Context) void {
    self.globals_manager.deinit();
    self.runtime.deinit();
    self.allocator.destroy(self.runtime);
}

pub fn pull(self: *Context) !void {
    _ = self;
}
