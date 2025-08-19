const std = @import("std");

const Runtime = @import("Runtime.zig");
const types = @import("types.zig");
const protocols = @import("protocols");
const Buffer = @import("Buffer.zig");

pub const interface = "wl_shm_pool";
pub const version = 2;

const ShmPool = @This();

object_id: types.ObjectId,
runtime: *Runtime,
fd: std.fs.File,
data: []align(4096) u8,

pub fn init(object: *ShmPool, object_id: types.ObjectId, runtime: *Runtime, fd: std.fs.File, data: []align(4096) u8) !void {
    object.* = .{
        .object_id = object_id,
        .runtime = runtime,
        .fd = fd,
        .data = data,
    };
    try runtime.registerObject(object);
}
pub fn deinit(self: *ShmPool) void {
    self.runtime.unregisterObject(self.object_id);
    self.runtime.sendRequest(self.object_id, 1, .{}) catch {};

    self.fd.close();
    std.posix.munmap(self.data);
}

pub fn createBuffer(
    self: *const ShmPool,
    buffer: *Buffer,
    /// buffer byte offset within the pool
    offset: i32,
    /// buffer width, in pixels
    width: i32,
    /// buffer height, in pixels
    height: i32,
    /// number of bytes from the beginning of one row to the beginning of the next row
    stride: i32,
    /// buffer pixel format
    format: protocols.wayland.WlShm.Format,
) !void {
    const buffer_id = self.runtime.getId();
    try Buffer.init(buffer, buffer_id, self.runtime, self.data[@intCast(offset)..][0..@intCast(stride * height)]);
    errdefer buffer.deinit();
    try self.runtime.sendRequest(
        self.object_id,
        0,
        .{
            buffer_id,
            offset,
            width,
            height,
            stride,
            format,
        },
    );
}

pub fn resize(
    self: *ShmPool,
    /// new size of the pool, in bytes
    size: usize,
) !void {
    std.debug.print("resize\n", .{});
    std.posix.munmap(self.data);
    try self.fd.setEndPos(size);
    self.data = try std.posix.mmap(
        null,
        size,
        std.posix.PROT.READ | std.posix.PROT.WRITE,
        std.posix.MAP{
            .TYPE = .SHARED,
        },
        self.fd.handle,
        0,
    );

    try self.runtime.sendRequest(self.object_id, 2, .{
        @as(i32, @intCast(size)),
    });
}

pub fn handleError(self: *ShmPool, code: u32, message: []const u8) void {
    std.debug.panic("Wayland Error recived on ShmPool(id: {}, code: {}, message: {s})", .{ self.object_id, @as(protocols.wayland.WlDisplay.Error, @enumFromInt(code)), message });
}
