const std = @import("std");

const wayland_client = @import("wayland_client");

const Context = @import("Context.zig");
const Window = @import("Window.zig");
const Buffer = @import("Buffer.zig");

const Frame = @This();

data: []u8,
format: wayland_client.protocols.wayland.WlShm.Format,
buffer: wayland_client.protocols.wayland.WlBuffer,

pub fn deinit(self: *const Frame) void {
    self.buffer.deinit();
}
