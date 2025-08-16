pub const types = @import("types.zig");
pub const Runtime = @import("Runtime.zig");
pub const protocols = @import("protocols");
pub const Display = @import("Display.zig");
pub const Registry = @import("Registry.zig");

test "callback sync" {
    const std = @import("std");
    var runtime = try Runtime.init(std.testing.allocator);
    defer runtime.deinit();

    _ = try std.Thread.spawn(.{}, Runtime.pullEvents, .{&runtime});

    const display = try runtime.display();
    defer display.deinit();

    const callback = try display.sync();
    defer callback.deinit();

    std.Thread.sleep(1_000_000_000);

    const ret = try callback.nextDone();

    try std.testing.expect(ret != null);
}

test {
    @import("std").testing.refAllDecls(@This());
}
