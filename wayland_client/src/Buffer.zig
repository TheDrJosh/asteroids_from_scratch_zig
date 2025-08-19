const std = @import("std");

const Runtime = @import("Runtime.zig");
const types = @import("types.zig");
const protocols = @import("protocols");

const Buffer = @This();

wl_buffer: *protocols.wayland.WlBuffer,
data: []u8,
is_released: bool,

pub fn init(object_id: types.ObjectId, runtime: *Runtime, data: []u8) !Buffer {
    const wl_buffer = try protocols.wayland.WlBuffer.init(object_id, runtime);

    return .{
        .wl_buffer = wl_buffer,
        .data = data,
        .is_released = false,
    };
}
pub fn deinit(self: *const Buffer) void {
    self.wl_buffer.deinit();
}

pub fn isReleased(self: *Buffer) bool {
    if (try self.wl_buffer.nextRelease()) {
        self.is_released = true;
    }
    return self.is_released;
}
