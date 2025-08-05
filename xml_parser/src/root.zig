const std = @import("std");

pub const Document = @import("Document.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
