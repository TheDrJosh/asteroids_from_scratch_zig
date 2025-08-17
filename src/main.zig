const std = @import("std");

const window_lib = @import("window_lib");

const Pixel = packed struct(u32) {
    b: u8,
    g: u8,
    r: u8,
    _: u8 = 0,

    pub fn splat(c: u8) Pixel {
        return .{
            .r = c,
            .g = c,
            .b = c,
        };
    }

    pub fn hsv(h: f64, s: f64, v: f64) Pixel {
        const rh = @mod(h, 360);

        const c = v * s;
        const x = c * (1 - @abs(@mod((rh / 60), 2) - 1));
        const m = v - c;

        return if (0 <= rh and rh < 60) Pixel{
            .r = @intFromFloat((c + m) * 255),
            .g = @intFromFloat((x + m) * 255),
            .b = @intFromFloat((m) * 255),
        } else if (60 <= rh and rh < 120) Pixel{
            .r = @intFromFloat((x + m) * 255),
            .g = @intFromFloat((c + m) * 255),
            .b = @intFromFloat((m) * 255),
        } else if (120 <= rh and rh < 180) Pixel{
            .r = @intFromFloat((m) * 255),
            .g = @intFromFloat((c + m) * 255),
            .b = @intFromFloat((x + m) * 255),
        } else if (180 <= rh and rh < 240) Pixel{
            .r = @intFromFloat((m) * 255),
            .g = @intFromFloat((x + m) * 255),
            .b = @intFromFloat((c + m) * 255),
        } else if (240 <= rh and rh < 300) Pixel{
            .r = @intFromFloat((x + m) * 255),
            .g = @intFromFloat((m) * 255),
            .b = @intFromFloat((c + m) * 255),
        } else if (300 <= rh and rh < 360) Pixel{
            .r = @intFromFloat((c + m) * 255),
            .g = @intFromFloat((m) * 255),
            .b = @intFromFloat((x + m) * 255),
        } else unreachable;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var context = try window_lib.Context.init(allocator);
    defer context.deinit();

    var window = try window_lib.Window.init(&context, .{
        .title = "test",
    });
    defer window.deinit();

    var width: u32 = 800;
    var height: u32 = 600;

    var last_frame = std.time.nanoTimestamp();
    var frame_number: u64 = 0;

    while (!(try window.shouldClose())) {
        defer frame_number += 1;

        if (try window.xdg_surface.nextConfigure()) |config_event| {
            while (try window.toplevel_surface.nextConfigure()) |toplevel_config_event| {
                defer toplevel_config_event.states.deinit();

                if (toplevel_config_event.width > 0 and toplevel_config_event.height > 0) {
                    width = @intCast(toplevel_config_event.width);
                    height = @intCast(toplevel_config_event.height);
                }
            }
            try window.xdg_surface.ackConfigure(config_event.serial);
        }

        const buffer = try context.shared_memory_manager.createBuffer(
            window_lib.Context.SharedMemoryManager.Buffer.calculateSize(
                width,
                height,
                .xrgb8888,
            ),
        );
        defer buffer.deinit();

        const frame = try buffer.createFrame(
            0,
            width,
            height,
            .xrgb8888,
        );
        defer frame.deinit();

        const pixels = std.mem.bytesAsSlice(Pixel, frame.data);

        const color = Pixel.hsv(@as(f64, @floatFromInt(frame_number)) / 2, 1, 1);

        for (0..height) |y| {
            for (0..width) |x| {
                if ((x + y / 32 * 32) % 64 < 32) {
                    pixels[y * width + x] = color;
                } else {
                    pixels[y * width + x] = Pixel.splat(0);
                }
            }
        }

        const current_frame = std.time.nanoTimestamp();
        // std.debug.print("fps: {}\n", .{1 / (@as(f64, @floatFromInt(current_frame - last_frame)) / std.time.ns_per_s)});
        last_frame = current_frame;

        try window.surface.attach(frame.buffer, 0, 0);
        try window.surface.damage(0, 0, @intCast(width), @intCast(height));
        try window.surface.commit();

        try context.keepAlive();
    }
}
