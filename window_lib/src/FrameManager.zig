const std = @import("std");

const Context = @import("Context.zig");
const wayland_client = @import("wayland_client");

const FrameManager = @This();

shm: wayland_client.Shm,
pool: ?wayland_client.ShmPool,
buffers: std.ArrayList(BufferInfo),
allocator: std.mem.Allocator,

const BufferInfo = union(enum) {
    empty: struct {
        size: usize,
    },
    filled: struct {
        id: u32,
        size: usize,
        buffer: *wayland_client.Buffer,
    },
};

pub fn init(frame_manager: *FrameManager, allocator: std.mem.Allocator, context: *Context) !void {
    frame_manager.* = .{
        .pool = null,
        .buffers = .empty,
        .allocator = allocator,
        .shm = undefined,
    };
    try context.registry.bind(wayland_client.Shm, &frame_manager.shm);
    errdefer frame_manager.shm.deinit();

    try context.display.sync();
}

pub fn deinit(self: *FrameManager) void {
    for (self.buffers.items) |*info| {
        switch (info.*) {
            .filled => |*filled_info| {
                filled_info.buffer.deinit();
                self.allocator.destroy(filled_info.buffer);
            },
            .empty => {},
        }
    }

    self.buffers.deinit(self.allocator);
    if (self.pool) |*pool| {
        pool.deinit();
    }
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

        self.pool = undefined;
        try self.shm.createPool(&self.pool.?, name, width * height * @sizeOf(Pixel));

        const buffer = try self.allocator.create(wayland_client.Buffer);
        try self.pool.?.createBuffer(
            buffer,
            0,
            @intCast(width),
            @intCast(height),
            @intCast(width * @sizeOf(Pixel)),
            Pixel.format,
        );

        try self.buffers.append(self.allocator, .{
            .filled = .{
                .id = buffer.wl_buffer.object_id,
                .size = width * height * @sizeOf(Pixel),
                .buffer = buffer,
            },
        });

        return .{
            .pixels = std.mem.bytesAsSlice(Pixel, buffer.data),
            .width = width,
            .buffer_id = buffer.wl_buffer.object_id,
            .frame_manager = self,
        };
    } else {
        for (self.buffers.items) |*buf_info| {
            switch (buf_info.*) {
                .filled => |*filled_buf_info| {
                    if (filled_buf_info.buffer.isReleased()) {
                        filled_buf_info.buffer.deinit();
                        self.allocator.destroy(filled_buf_info.buffer);
                        buf_info.* = .{
                            .empty = .{
                                .size = filled_buf_info.size,
                            },
                        };
                    }
                },
                .empty => {},
            }
        }

        {
            var i: u32 = 0;
            while (i < self.buffers.items.len - 1) {
                switch (self.buffers.items[i]) {
                    .filled => {
                        i += 1;
                    },
                    .empty => |*info| {
                        switch (self.buffers.items[i + 1]) {
                            .filled => {
                                i += 2;
                            },
                            .empty => |e| {
                                info.size += e.size;
                                _ = self.buffers.orderedRemove(i + 1);
                            },
                        }
                    },
                }
            }
        }

        var offset: usize = 0;
        for (0..self.buffers.items.len) |i| {
            switch (self.buffers.items[i]) {
                .empty => |info| {
                    if (info.size >= (width * height * @sizeOf(Pixel))) {
                        const buffer = try self.allocator.create(wayland_client.Buffer);
                        try self.pool.?.createBuffer(
                            buffer,
                            @intCast(offset),
                            @intCast(width),
                            @intCast(height),
                            @intCast(width * @sizeOf(Pixel)),
                            Pixel.format,
                        );
                        self.buffers.items[i] = .{
                            .filled = .{
                                .id = buffer.wl_buffer.object_id,
                                .size = width * height * @sizeOf(Pixel),
                                .buffer = buffer,
                            },
                        };
                        if (info.size != (width * height * @sizeOf(Pixel))) {
                            try self.buffers.insert(self.allocator, i + 1, .{
                                .empty = .{
                                    .size = info.size - (width * height * @sizeOf(Pixel)),
                                },
                            });
                        }
                        return .{
                            .pixels = std.mem.bytesAsSlice(Pixel, buffer.data),
                            .width = width,
                            .buffer_id = buffer.wl_buffer.object_id,
                            .frame_manager = self,
                        };
                    }
                    offset += info.size;
                },
                .filled => |info| {
                    offset += info.size;
                },
            }
        }

        try self.pool.?.resize(self.pool.?.data.len + width * height * @sizeOf(Pixel));
        try self.buffers.append(self.allocator, .{
            .empty = .{
                .size = width * height * @sizeOf(Pixel),
            },
        });

        return try self.createFrame(width, height, Pixel);

        // @panic("TODO");
    }
}

pub fn getBuffer(self: *FrameManager, id: u32) ?*wayland_client.Buffer {
    for (self.buffers.items) |*b| {
        switch (b.*) {
            .filled => |*f| {
                if (f.id == id) {
                    return f.buffer;
                }
            },
            .empty => {},
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

        pub fn forceDestroy(self: *const Self) void {
            const buf = self.getBuffer() catch unreachable;
            buf.is_released = true;
        }

        pub fn getBuffer(self: *const Self) !*wayland_client.Buffer {
            return self.frame_manager.getBuffer(self.buffer_id) orelse return error.buffer_destroyed;
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
