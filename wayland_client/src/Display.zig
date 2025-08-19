const std = @import("std");
const Runtime = @import("Runtime.zig");
const protocols = @import("protocols");
const Registry = @import("Registry.zig");
const Message = @import("Message.zig");
const types = @import("types.zig");

const Display = @This();

runtime: *Runtime,

pub const object_id = 1;
pub const interface = "wl_display";

pub fn init(runtime: *Runtime) !*Display {
    const display = try runtime.allocator.create(Display);
    errdefer display.deinit();
    display.* = .{
        .runtime = runtime,
    };
    try runtime.registerObject(display);
    return display;
}

pub fn deinit(self: *const Display) void {
    self.runtime.unregisterObject(object_id);

    self.runtime.allocator.destroy(self);
}

pub fn sync(self: *const Display) !void {
    const callback_id = self.runtime.getId();
    const callback = try protocols.wayland.WlCallback.init(callback_id, self.runtime);
    defer callback.deinit();
    try self.runtime.sendRequest(Display.object_id, 0, .{
        callback_id,
    });

    while (try callback.nextDone() == null) {}
}

pub fn getRegistry(self: *const Display) !*Registry {
    const registry_id = self.runtime.getId();
    const registry = try Registry.init(registry_id, self.runtime);
    errdefer registry.deinit();

    try self.runtime.sendRequest(Display.object_id, 1, .{
        registry_id,
    });

    try self.sync();

    return registry;
}

pub fn handleEvent(self: *Display, msg: Message) void {
    switch (msg.info.opcode) {
        0 => {
            const parsed_msg = msg.parse(protocols.wayland.WlDisplay.ErrorEvent, self.runtime) catch unreachable;
            defer parsed_msg.args.deinit();

            self.runtime.object_register_mutex.lock();
            defer self.runtime.object_register_mutex.unlock();

            if (self.runtime.object_register.get(parsed_msg.args.object_id)) |inter| {
                if (inter.vtable.handleError) |inter_handleError| {
                    inter_handleError(inter.context, parsed_msg.args.code, parsed_msg.args.message.data());
                }
            }
            std.debug.panic(
                "Wayland Error recived on unknown object(id: {}, code: {}, message: {s})",
                .{
                    parsed_msg.args.object_id,
                    parsed_msg.args.code,
                    parsed_msg.args.message.data(),
                },
            );
        },
        1 => {
            const parsed_msg = msg.parse(protocols.wayland.WlDisplay.DeleteIdEvent, self.runtime) catch unreachable;

            self.runtime.unregisterObject(parsed_msg.args.id);

            self.runtime.reuse_ids_mutex.lock();
            defer self.runtime.reuse_ids_mutex.unlock();

            self.runtime.reuse_ids.add(parsed_msg.args.id) catch unreachable;
        },
        else => {},
    }
}

pub fn handleError(self: *Display, code: u32, message: []const u8) void {
    _ = self;
    std.debug.panic(
        "Wayland Error recived on Display(code: {}, message: {s})",
        .{
            @as(protocols.wayland.WlDisplay.Error, @enumFromInt(code)),
            message,
        },
    );
}
