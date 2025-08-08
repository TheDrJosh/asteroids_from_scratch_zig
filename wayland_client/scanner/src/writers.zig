const std = @import("std");

//TODO make use new api
pub const TabWriter = struct {
    const Self = @This();
    indent: u32,
    inner_writer: *std.Io.Writer,
    interface: std.Io.Writer,

    pub fn init(inner_writer: *std.io.Writer) Self {
        return Self{
            .indent = 0,
            .inner_writer = inner_writer,
            .interface = .{ .buffer = &.{}, .vtable = &.{ .drain = drain } },
        };
    }

    fn drain(w: *std.io.Writer, data: []const []const u8, splat: usize) std.io.Writer.Error!usize {
        _ = splat;
        const self: *TabWriter = @alignCast(@fieldParentPtr("interface", w));

        const buffered = w.buffered();
        if (buffered.len != 0) return w.consume(try self.write(buffered));
        return try self.write(data[0]);
    }

    fn write(self: *Self, bytes: []const u8) std.Io.Writer.Error!usize {
        if (std.mem.indexOf(u8, bytes, "\n")) |new_line_index| {
            //TODO - Make this more efficent (no recurtion)

            const n = try self.inner_writer.write(bytes[0..(new_line_index + 1)]);

            if (n < new_line_index + 1) {
                return n;
            }

            for (0..(self.indent * 4)) |_| {
                try self.inner_writer.writeByte(' ');
            }

            return new_line_index + 1 + try self.write(bytes[(new_line_index + 1)..]);
        } else {
            return try self.inner_writer.write(bytes);
        }
    }
};
