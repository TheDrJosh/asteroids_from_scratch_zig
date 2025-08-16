const std = @import("std");

const wayland_client = @import("wayland_client");

const SharedMemoryManager = @import("SharedMemoryManager.zig");
pub const Frame = @import("Frame.zig");

const Buffer = @This();

data: []align(std.heap.page_size_min) u8,
pool: *wayland_client.protocols.wayland.WlShmPool,

pub fn deinit(self: *const Buffer) void {
    std.posix.munmap(self.data);
    self.pool.deinit();
}

pub fn createFrame(
    self: *const Buffer,
    offset: u32,
    width: u32,
    height: u32,
    format: wayland_client.protocols.wayland.WlShm.Format,
) !Frame {
    const pixel_width = formatWidth(format);

    const buffer = try self.pool.createBuffer(
        @intCast(offset),
        @intCast(width),
        @intCast(height),
        @intCast(width * pixel_width),
        format,
    );

    return .{
        .data = self.data[offset..(offset + (width * pixel_width * height))],
        .format = format,
        .buffer = buffer,
    };
}

pub fn calculateSize(
    width: u32,
    height: u32,
    format: wayland_client.protocols.wayland.WlShm.Format,
) u32 {
    return width * formatWidth(format) * height;
}

pub fn formatWidth(format: wayland_client.protocols.wayland.WlShm.Format) u32 {
    return switch (format) {
        .argb8888 => 4, //32
        .xrgb8888 => 4, //32
        else => @panic("unsupported format"),
        // .c8 => 8,
        // .rgb332 => 8,
        // .bgr233 => 8,
        // .xrgb4444 => 16,
        // .xbgr4444 => 16,
        // .rgbx4444 => 16,
        // .bgrx4444 => 16,
        // .argb4444 => 16,
        // .abgr4444 => 16,
        // .rgba4444 => 16,
        // .bgra4444 => 16,
        // .xrgb1555 => 16,
        // .xbgr1555 => 16,
        // .rgbx5551 => 16,
        // .bgrx5551 => 16,
        // .argb1555 => 16,
        // .abgr1555 => 16,
        // .rgba5551 => 16,
        // .bgra5551 => 16,
        // .rgb565 => 16,
        // .bgr565 => 16,
        // .rgb888 => 24,
        // .bgr888 => 24,
        // .xbgr8888 => 32,
        // .rgbx8888 => 32,
        // .bgrx8888 => 32,
        // .abgr8888 => 32,
        // .rgba8888 => 32,
        // .bgra8888 => 32,
        // .xrgb2101010 => 32,
        // .xbgr2101010 => 32,
        // .rgbx1010102 => 32,
        // .bgrx1010102 => 32,
        // .argb2101010 => 32,
        // .abgr2101010 => 32,
        // .rgba1010102 => 32,
        // .bgra1010102 => 32,
        // .yuyv => 32,
        // .yvyu => 32,
        // .uyvy => 32,
        // .vyuy => 32,
        // .ayuv => 32,
        // .nv12 => 12,
        // .nv21 => 12,
        // .nv16 => 16,
        // .nv61 => 16,
        // .yuv410 => 9,
        // .yvu410 => 9,
        // .yuv411 => 12,
        // .yvu411 => 12,
        // .yuv420 => 12,
        // .yvu420 => 12,
        // .yuv422 => 16,
        // .yvu422 => 16,
        // .yuv444 => 24,
        // .yvu444 => 24,
        // .r8 => 8,
        // .r16 => 16,
        // .rg88 => 16,
        // .gr88 => 16,
        // .rg1616 => 32,
        // .gr1616 => 32,
        // .xrgb16161616f => 64,
        // .xbgr16161616f => 64,
        // .argb16161616f => 64,
        // .abgr16161616f => 64,
        // .xyuv8888 => 32,
        // .vuy888 => 24,
        // .vuy101010 => 30,
        // .y210 => 20,
        // .y212 => 24,
        // .y216 => 32,
        // .y410 => 32,
        // .y412 => 48,
        // .y416 => 64,
        // .xvyu2101010 => 32,
        // .xvyu12_16161616 => 64,
        // .xvyu16161616 => 64,
        // .y0l0 => 64,
        // .x0l0 => 64,
        // .y0l2 => 64,
        // .x0l2 => 64,
        // .yuv420_8bit => 8,
        // .yuv420_10bit => 10,
        // .xrgb8888_a8 => 40,
        // .xbgr8888_a8 => 40,
        // .rgbx8888_a8 => 40,
        // .bgrx8888_a8 => 40,
        // .rgb888_a8 => 32,
        // .bgr888_a8 => 32,
        // .rgb565_a8 => 32,
        // .bgr565_a8 => 32,
        // .nv24 => 24,
        // .nv42 => 24,
        // .p210 => 20,
        // .p010 => 15,
        // .p012 => 18,
        // .p016 => 24,
        // .axbxgxrx106106106106 => 64,
        // .nv15 => 15,
        // .q410 => 30,
        // .q401 => 31,
        // .xrgb16161616 => 64,
        // .xbgr16161616 => 64,
        // .argb16161616 => 64,
        // .abgr16161616 => 64,
        // .c1 => 1,
        // .c2 => 2,
        // .c4 => 4,
        // .d1 => 1,
        // .d2 => 2,
        // .d4 => 4,
        // .d8 => 8,
        // .r1 => 1,
        // .r2 => 2,
        // .r4 => 4,
        // .r10 => 16,
        // .r12 => 16,
        // .avuy8888 => 32,
        // .xvuy8888 => 32,
        // .p030 => 30,
    };
}
