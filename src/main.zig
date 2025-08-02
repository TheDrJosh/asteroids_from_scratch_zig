const std = @import("std");
const WaylandRuntime = @import("wayland/WaylandRuntime.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var runtime = try WaylandRuntime.init(allocator);
    defer runtime.deinit();

    try runtime.sendRequest(1, 0, .{@as(u32, 2)});

    std.Thread.sleep(1000000000);

    const ret = try runtime.next(2, 0, struct { callback_data: u32 });

    std.debug.print("{any}\n", .{ret});
}
