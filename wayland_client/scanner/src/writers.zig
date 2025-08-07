const std = @import("std");

pub fn TabWriter(W: type) type {
    return struct {
        const Self = @This();
        indent: u32,
        inner_writer: W,

        pub const Writer = std.io.GenericWriter(*Self, W.Error, write);

        pub fn init(inner_writer: W) Self {
            return Self{
                .indent = 0,
                .inner_writer = inner_writer,
            };
        }

        pub fn write(self: *Self, bytes: []const u8) W.Error!usize {
            if (std.mem.indexOf(u8, bytes, "\n")) |new_line_index| {
                //TODO - Make this more efficent (no recurtion)

                const n = try self.inner_writer.write(bytes[0..(new_line_index + 1)]);

                if (n < new_line_index + 1) {
                    return n;
                }

                try self.inner_writer.writeByteNTimes(' ', self.indent * 4);

                return new_line_index + 1 + try self.write(bytes[(new_line_index + 1)..]);
            } else {
                return try self.inner_writer.write(bytes);
            }
        }

        pub fn writer(self: *Self) Writer {
            return Writer{
                .context = self,
            };
        }
    };
}
