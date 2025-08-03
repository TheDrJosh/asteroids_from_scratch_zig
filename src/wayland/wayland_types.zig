const std = @import("std");

pub const ObjectId = u32;

pub const NewId = struct {
    interface: []const u8,
    version: u32,
    id: u32,
};

pub const Fixed = packed struct(u32) {
    fractional: u8,
    whole: u24,

    pub fn toFloat32(self: Fixed) f32 {
        return self.toFloat(f32);
    }

    pub fn toFloat64(self: Fixed) f64 {
        return self.toFloat(f64);
    }

    fn toFloat(self: Fixed, comptime T: type) T {
        return @as(T, @floatFromInt(@as(u32, @bitCast(self)))) / 256;
    }
};

pub const String = struct {
    data: std.ArrayList(u8),
};

pub const Fd = struct {
    fd: std.posix.fd_t,
};
