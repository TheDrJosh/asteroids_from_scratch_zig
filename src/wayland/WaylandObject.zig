const std = @import("std");

const WaylandStream = @import("WaylandStream.zig");

pub const ObjectId = u32;

ptr: *anyopaque,
vtable: *const VTable,

const VTable = struct {
    receiveEvent: *const fn (self: *anyopaque, event: WaylandStream.Message) void,
    id: *const fn (self: *anyopaque) ObjectId,
};
