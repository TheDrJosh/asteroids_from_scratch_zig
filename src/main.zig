const std = @import("std");
const WaylandRuntime = @import("wayland/WaylandRuntime.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const runtime = try WaylandRuntime.init(allocator);
    defer runtime.deinit();

    try runtime.sendRequest(1, 0, .{@as(u32, 2)});

    
}
