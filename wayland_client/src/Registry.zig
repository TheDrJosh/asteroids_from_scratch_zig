const std = @import("std");
const Runtime = @import("Runtime.zig");
const protocols = @import("protocols");
const Message = @import("Message.zig");
const types = @import("types.zig");

const Registry = @This();

object_id: types.ObjectId,
runtime: *Runtime,
globals: std.ArrayList(GlobalInfo),
globals_mutex: std.Thread.Mutex,

const GlobalInfo = struct {
    name: u32,
    interface: types.String,
    version: u32,
};

pub const interface = "wl_registry";

pub fn init(object_id: types.ObjectId, runtime: *Runtime) !*Registry {
    const registry = try runtime.allocator.create(Registry);
    registry.* = .{
        .object_id = object_id,
        .runtime = runtime,
        .globals = .empty,
        .globals_mutex = .{},
    };
    try runtime.registerObject(registry);
    return registry;
}

pub fn deinit(self: *Registry) void {
    self.runtime.unregisterObject(self.object_id);

    self.globals_mutex.lock();

    for (self.globals.items) |g| {
        g.interface.deinit();
    }
    self.globals.deinit(self.runtime.allocator);
    self.globals_mutex.unlock();

    self.runtime.allocator.destroy(self);
}

pub fn bind(self: *Registry, T: type) !?*T {
    self.globals_mutex.lock();
    defer self.globals_mutex.unlock();

    for (self.globals.items) |global_info| {
        if (std.mem.eql(u8, global_info.interface.data(), T.interface)) {
            const global_id = self.runtime.getId();
            const global = try T.init(global_id, self.runtime);
            try self.runtime.sendRequest(self.object_id, 0, .{ global_info.name, types.NewId{
                .id = global_id,
                .interface = .{ .static = T.interface },
                .version = global_info.version,
            } });

            return global;
        }
    }

    return null;
}

pub fn handleEvent(self: *Registry, msg: Message) void {
    switch (msg.info.opcode) {
        0 => {
            const parsed_msg = msg.parse(protocols.wayland.WlRegistry.GlobalEvent, self.runtime) catch unreachable;

            self.globals_mutex.lock();
            defer self.globals_mutex.unlock();

            self.globals.append(self.runtime.allocator, .{
                .name = parsed_msg.args.name,
                .version = parsed_msg.args.version,
                .interface = parsed_msg.args.interface,
            }) catch unreachable;
        },
        1 => {
            const parsed_msg = msg.parse(protocols.wayland.WlRegistry.GlobalRemoveEvent, self.runtime) catch unreachable;

            self.globals_mutex.lock();
            defer self.globals_mutex.unlock();

            for (0..self.globals.items.len) |i| {
                if (self.globals.items[i].name == parsed_msg.args.name) {
                    self.globals.swapRemove(i).interface.deinit();
                    break;
                }
            }
        },
        else => {},
    }
}

pub fn handleError(self: *Registry, code: u32, message: []const u8) void {
    std.debug.panic("Wayland Error recived on Registry(id: {}, code: {}, message: {s})", .{ self.object_id, @as(protocols.wayland.WlDisplay.Error, @enumFromInt(code)), message });
}
