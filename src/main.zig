const std = @import("std");
const WaylandRuntime = @import("wayland/WaylandRuntime.zig");
const wayland_types = @import("wayland/wayland_types.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var runtime = try WaylandRuntime.init(allocator);
    defer runtime.deinit();

    const registry_id = runtime.getId();

    try runtime.sendRequest(1, 1, .{registry_id});

    std.Thread.sleep(1_000_000_000);

    while (try runtime.next(registry_id, 0, struct { name: u32, interface: wayland_types.String, version: u32 })) |global| {
        defer global.args.interface.data.deinit();
        std.debug.print("Global(name: {}, interface: {s}, version: {})\n", .{ global.args.name, global.args.interface.data.items, global.args.version });
    }
}

test "callback sync" {
    var runtime = try WaylandRuntime.init(std.testing.allocator);
    defer runtime.deinit();

    const callback_id = runtime.getId();

    try runtime.sendRequest(WaylandRuntime.display_id, 0, .{callback_id});

    const ret = try runtime.next(callback_id, 0, struct { callback_data: u32 });

    try std.testing.expect(ret != null);
}
