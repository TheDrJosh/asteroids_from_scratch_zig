const std = @import("std");
const wayland = @import("../wayland.zig");
const TabWriter = @import("../writers.zig").TabWriter;
const utils = @import("../utils.zig");

pub fn processEnums(tab_writer: *TabWriter(std.fs.File.Writer), interface: wayland.Interface, allocator: std.mem.Allocator) !void {
    const writer = tab_writer.writer();
    
    for (interface.enums.items) |@"enum"| {
        try utils.writeFormatedDocComment(
            writer,
            @"enum".description,
            null,
            null,
            @"enum".since,
            null,
            allocator,
        );

        try writer.writeAll("pub const ");

        try utils.writePascalCase(@"enum".name.items, writer);

        tab_writer.indent += 1;

        if (@"enum".bitfield) {
            try writer.writeAll(" = packed struct(u32) {");

            var bits = [1]?wayland.Entry{null} ** 32;

            for (@"enum".entries.items) |entry| {
                if (entry.value > 0 and std.math.isPowerOfTwo(@as(u64, @intCast(entry.value)))) {
                    bits[std.math.log2_int(u64, @intCast(entry.value))] = entry;
                }
            }

            var i: usize = 0;
            var empty_count: ?usize = null;
            for (bits) |bit| {
                if (bit) |b| {
                    if (empty_count) |ec| {
                        try writer.print("\n_{d}: u{d} = 0,", .{ i, ec });
                        i += 1;
                    }

                    try utils.writeFormatedDocComment(
                        writer,
                        null,
                        b.summary,
                        null,
                        b.since,
                        b.deprecated_since,
                        allocator,
                    );

                    try writer.print("{s}: bool = false,", .{b.name.items});
                } else {
                    if (empty_count) |*ec| {
                        ec.* += 1;
                    } else {
                        empty_count = 1;
                    }
                }
            }

            for (@"enum".entries.items) |entry| {
                if (entry.value > 0 and std.math.isPowerOfTwo(@as(u64, @intCast(entry.value)))) {
                    continue;
                }

                try utils.writeFormatedDocComment(
                    writer,
                    null,
                    entry.summary,
                    null,
                    entry.since,
                    entry.deprecated_since,
                    allocator,
                );

                try writer.writeAll("pub const ");
                for (entry.name.items) |c| {
                    try writer.writeByte(std.ascii.toUpper(c));
                }
                try writer.writeAll(" = ");

                try utils.writePascalCase(@"enum".name.items, writer);

                try writer.writeAll("{ ");

                const set_bits = std.bit_set.IntegerBitSet(32){
                    .mask = @as(u32, @intCast(entry.value)),
                };

                for (0..32) |index| {
                    if (set_bits.isSet(index)) {
                        try writer.print(".{s} = true, ", .{bits[index].?.name.items});
                    }
                }

                try writer.writeAll("};\n");
            }
        } else {
            try writer.writeAll(" = enum(u32) {");

            for (@"enum".entries.items) |entry| {
                var comment = std.ArrayList(u8).init(allocator);
                defer comment.deinit();

                try utils.writeFormatedDocComment(
                    writer,
                    null,
                    entry.summary,
                    null,
                    entry.since,
                    entry.deprecated_since,
                    allocator,
                );

                try utils.escapeIdentifier(writer, entry.name.items);
                try writer.writeAll(" = ");
                try writer.print("{}", .{entry.value});
                try writer.writeAll(",");
            }
        }

        tab_writer.indent -= 1;

        try writer.writeAll("\n};\n");
    }
}
