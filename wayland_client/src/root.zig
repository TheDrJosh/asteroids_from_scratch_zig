pub const types = @import("types.zig");
pub const WaylandRuntime = @import("WaylandRuntime.zig");
pub const protocols = @import("protocols");

test "callback sync" {
    const std = @import("std");
    var runtime = try WaylandRuntime.init(std.testing.allocator);
    defer runtime.deinit();

    const display = runtime.display();

    const callback = try display.sync();

    std.Thread.sleep(1_000_000_000);

    const ret = try callback.nextDone();

    try std.testing.expect(ret != null);
}

test {
    @import("std").testing.refAllDecls(@This());
}
