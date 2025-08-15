const std = @import("std");

const wayland_client = @import("wayland_client");

const GlobalsManager = @This();

registry: wayland_client.protocols.wayland.WlRegistry,
globals: std.array_list.Managed(GlobalInfo),

const GlobalInfo = struct {
    name: u32,
    interface: wayland_client.types.String,
    version: u32,
};

pub fn init(runtime: *wayland_client.WaylandRuntime, allocator: std.mem.Allocator) !GlobalsManager {
    const registry = try runtime.display().getRegistry();

    const callback = try registry.runtime.display().sync();

    while (try callback.nextDone() == null) {}

    return .{
        .registry = registry,
        .globals = std.array_list.Managed(GlobalInfo).init(allocator),
    };
}

pub fn deinit(self: *const GlobalsManager) void {
    for (self.globals.items) |g| {
        g.interface.deinit();
    }
    self.globals.deinit();
}

pub fn bind(self: *GlobalsManager, T: type) !?T {
    while (try self.registry.runtime.next(&[_]type{
        wayland_client.protocols.wayland.WlRegistry.GlobalEvent,
        wayland_client.protocols.wayland.WlRegistry.GlobalRemoveEvent,
    }, [2]wayland_client.types.ObjectId{
        self.registry.object_id,
        self.registry.object_id,
    })) |e| {
        switch (e) {
            .@"0" => |global_event| {
                try self.globals.append(.{
                    .name = global_event.name,
                    .version = global_event.version,
                    .interface = global_event.interface,
                });
                // std.debug.print("Global(name: {}, interface: {s}, version: {})\n", .{ global.name, global.interface.data(), global.version });
            },
            .@"1" => |global_remove_event| {
                for (0..self.globals.items.len) |i| {
                    if (self.globals.items[i].name == global_remove_event.name) {
                        self.globals.swapRemove(i).interface.deinit();
                        break;
                    }
                }
            },
        }
    }

    for (0..self.globals.items.len) |i| {
        if (std.mem.eql(u8, self.globals.items[i].interface.data(), T.interface)) {
            return (try self.registry.bind(self.globals.items[i].name, T, self.globals.items[i].version));
        }
    }
    return null;
}
