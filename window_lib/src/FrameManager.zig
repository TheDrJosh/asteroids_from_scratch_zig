const std = @import("std");

const Context = @import("Context.zig");
const wayland_client = @import("wayland_client");

const FrameManager = @This();

shm: *wayland_client.Shm,
pool: ?*wayland_client.ShmPool,
buffers: std.ArrayList(BufferInfo),
allocator: std.mem.Allocator,

const BufferInfo = struct {
    id: u32,
    offset: usize,
    size: usize,
    buffer: ?wayland_client.Buffer,
};

pub fn init(allocator: std.mem.Allocator, registry: *wayland_client.Registry) !FrameManager {
    const shm = try registry.bind(wayland_client.Shm) orelse unreachable;
    errdefer shm.deinit();

    return .{
        .shm = shm,
        .pool = null,
        .buffers = .empty,
        .allocator = allocator,
    };
}

pub fn deinit(self: *const FrameManager) void {
    if (self.pool) |pool| {
        pool.deinit();
    }
    self.buffers.deinit(self.allocator);
    self.shm.deinit();
}

pub fn createFrame(self: *FrameManager, width: u32, height: u32, comptime Pixel: type) !Frame(Pixel) {
    if (!self.shm.supportsFormat(Pixel.format)) {
        return error.unsupported_format;
    }

    if (self.pool == null) {
        var rand: u32 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&rand));

        var name_buf = [1]u8{0} ** 17;
        const name = try std.fmt.bufPrintZ(&name_buf, "/wl_shm-{X:0>8}", .{rand});

        self.pool = try self.shm.createPool(name, width * height * @sizeOf(Pixel));

        const buffer = try self.pool.?.createBuffer(
            0,
            @intCast(width),
            @intCast(height),
            @intCast(width * @sizeOf(Pixel)),
            Pixel.format,
        );

        try self.buffers.append(self.allocator, .{
            .id = buffer.wl_buffer.object_id,
            .offset = 0,
            .size = width * height * @sizeOf(Pixel),
            .buffer = buffer,
        });

        return .{
            .pixels = std.mem.bytesAsSlice(Pixel, buffer.data),
            .width = width,
            .buffer_id = buffer.wl_buffer.object_id,
            .frame_manager = self,
        };
    } else {

        
        @panic("TODO");
    }
}

pub fn getBuffer(self: *FrameManager, id: u32) ?*?wayland_client.Buffer {
    for (self.buffers.items) |*b| {
        if (b.id == id) {
            return &b.buffer;
        }
    }
    return null;
}

pub fn Frame(comptime Pixel: type) type {
    return struct {
        const Self = @This();

        width: u32,
        pixels: []align(1) Pixel,
        buffer_id: u32,
        frame_manager: *FrameManager,

        pub inline fn height(self: Self) u32 {
            return @intCast(self.pixels.len / self.width);
        }

        pub fn deinit(self: *const Self) void {
            const buf = self.getBuffer();
            if (buf.*) |*b| {
                b.deinit();
            }
            buf.* = null;
        }

        pub fn getBuffer(self: *const Self) *?wayland_client.Buffer {
            return self.frame_manager.getBuffer(self.buffer_id) orelse unreachable;
        }
    };
}

pub const PixelXrgb8888 = packed struct(u32) {
    b: u8,
    g: u8,
    r: u8,
    _: u8 = 0,

    const format = wayland_client.Shm.Format.xrgb8888;
};

pub const PixelArgb8888 = packed struct(u32) {
    b: u8,
    g: u8,
    r: u8,
    a: u8,

    const format = wayland_client.Shm.Format.argb8888;
};
