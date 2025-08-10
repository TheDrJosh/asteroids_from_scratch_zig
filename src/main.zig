const std = @import("std");

const window_lib = @import("window_lib");

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

    const width = 800;
    const height = 600;

    while (!(try window.shouldClose())) {
        if (try window.xdg_surface.nextConfigure()) |config_event| {
            try window.xdg_surface.ackConfigure(config_event.serial);
            const buffer = try context.shared_memory_manager.createBuffer(window_lib.Context.SharedMemoryManager.Buffer.calculateSize(
                width,
                height,
                .xrgb8888,
            ));
            defer buffer.deinit();

            const frame = try buffer.createFrame(0, width, height, .xrgb8888);
            defer frame.deinit();

            const pixels = std.mem.bytesAsSlice(u32, frame.data);

            for (0..height) |y| {
                for (0..width) |x| {
                    if ((x + y / 8 * 8) % 16 < 8) {
                        pixels[y * width + x] = 0xFFFFFFF;
                    } else {
                        pixels[y * width + x] = 0xFF000000;
                    }
                }
            }

            try window.surface.attach(frame.buffer, 0, 0);
            try window.surface.commit();
        }

        if (try context.wm_base.nextPing()) |ping| {
            try context.wm_base.pong(ping.serial);
        }
    }
}
