const std = @import("std");

const wayland = @import("wayland.zig");
const writers = @import("writers.zig");

pub fn processProtocol(protocol: wayland.Protocol, output_file_writer: std.fs.File.Writer, allocator: std.mem.Allocator) !void {
    var tab_writer = writers.TabWriter(std.fs.File.Writer).init(output_file_writer);
    const writer = tab_writer.writer();

    if (protocol.description) |desc| {
        try writeDocComment(writer, desc.description.items);
    }
    try writer.writeAll("pub const ");
    try writer.writeAll(protocol.name.items);
    tab_writer.indent += 1;
    try writer.writeAll(" = struct {");

    for (protocol.interfaces.items) |interface| {
        if (interface.description) |desc| {
            try writeDocComment(writer, desc.description.items);
        }
        try writer.writeAll("pub const ");
        try writeHumpCase(interface.name.items, writer);
        tab_writer.indent += 1;
        try writer.writeAll(" = struct {\n");

        try writer.writeAll("pub const interface = \"");
        try writer.writeAll(interface.name.items);
        try writer.print("\";\npub const version = {};\n", .{interface.version});

        try writer.writeAll("\nobject_id: types.ObjectId,\nruntime: *WaylandRuntime,\n");

        for (interface.enums.items) |@"enum"| {
            {
                var comment = std.ArrayList(u8).init(allocator);
                defer comment.deinit();

                if (@"enum".description) |desc| {
                    try comment.appendSlice("## summary\n\n");
                    try comment.appendSlice(desc.description.items);

                    try comment.appendSlice("\n\n");
                }

                if (@"enum".since) |since| {
                    try comment.appendSlice("## since\n\n");
                    try comment.writer().print("{}", .{since});

                    try comment.appendSlice("\n\n");
                }
                try writeDocComment(writer, comment.items);
            }

            try writer.writeAll("pub const ");

            try writeHumpCase(@"enum".name.items, writer);

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

                        var comment = std.ArrayList(u8).init(allocator);
                        defer comment.deinit();

                        if (b.summary) |summary| {
                            try comment.appendSlice("## summary\n\n");
                            try comment.appendSlice(summary.items);

                            try comment.appendSlice("\n\n");
                        }

                        if (b.since) |since| {
                            try comment.appendSlice("## since\n\n");
                            try comment.writer().print("{}", .{since});

                            try comment.appendSlice("\n\n");
                        }

                        if (b.deprecated_since) |deprecated_since| {
                            try comment.appendSlice("## deprecated since\n\n");
                            try comment.writer().print("{}", .{deprecated_since});
                        }

                        try writeDocComment(writer, comment.items);

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

                    var comment = std.ArrayList(u8).init(allocator);
                    defer comment.deinit();

                    if (entry.summary) |summary| {
                        try comment.appendSlice("## summary\n\n");
                        try comment.appendSlice(summary.items);

                        try comment.appendSlice("\n\n");
                    }

                    if (entry.since) |since| {
                        try comment.appendSlice("## since\n\n");
                        try comment.writer().print("{}", .{since});

                        try comment.appendSlice("\n\n");
                    }

                    if (entry.deprecated_since) |deprecated_since| {
                        try comment.appendSlice("## deprecated since\n\n");
                        try comment.writer().print("{}", .{deprecated_since});
                    }

                    try writeDocComment(writer, comment.items);

                    try writer.writeAll("pub const ");
                    for (entry.name.items) |c| {
                        try writer.writeByte(std.ascii.toUpper(c));
                    }
                    try writer.writeAll(" = ");

                    try writeHumpCase(@"enum".name.items, writer);

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

                    if (entry.summary) |summary| {
                        try comment.appendSlice("## summary\n\n");
                        try comment.appendSlice(summary.items);

                        try comment.appendSlice("\n\n");
                    }

                    if (entry.since) |since| {
                        try comment.appendSlice("## since\n\n");
                        try comment.writer().print("{}", .{since});

                        try comment.appendSlice("\n\n");
                    }

                    if (entry.deprecated_since) |deprecated_since| {
                        try comment.appendSlice("## deprecated since\n\n");
                        try comment.writer().print("{}", .{deprecated_since});
                    }

                    try writeDocComment(writer, comment.items);

                    try escapeIdentifier(writer, entry.name.items);
                    try writer.writeAll(" = ");
                    try writer.print("{}", .{entry.value});
                    try writer.writeAll(",");
                }
            }

            tab_writer.indent -= 1;

            try writer.writeAll("\n};\n");
        }

        for (interface.requests.items) |request| {
            {
                var comment = std.ArrayList(u8).init(allocator);
                defer comment.deinit();

                if (request.description) |desc| {
                    try comment.appendSlice("## summary\n\n");
                    try comment.appendSlice(desc.description.items);

                    try comment.appendSlice("\n\n");
                }

                if (request.since) |since| {
                    try comment.appendSlice("## since\n\n");
                    try comment.writer().print("{}", .{since});

                    try comment.appendSlice("\n\n");
                }

                if (request.deprecated_since) |deprecated_since| {
                    try comment.appendSlice("## deprecated since\n\n");
                    try comment.writer().print("{}", .{deprecated_since});

                    try comment.appendSlice("\n\n");
                }
                try writeDocComment(writer, comment.items);
            }

            try writer.writeAll("pub fn ");

            try writeCammelCase(request.name.items, writer);

            try writer.writeAll("(self: *const ");

            try writeHumpCase(interface.name.items, writer);

            for (request.args.items) |arg| {
                _ = arg;

                
            }

            try writer.writeAll(") void");

            tab_writer.indent += 1;

            try writer.writeAll("{\n");

            try writer.writeAll("_ = self;\n");

            tab_writer.indent -= 1;

            try writer.writeAll("\n}\n");
        }

        for (interface.events.items) |events| {
            {
                var comment = std.ArrayList(u8).init(allocator);
                defer comment.deinit();

                if (events.description) |desc| {
                    try comment.appendSlice("## summary\n\n");
                    try comment.appendSlice(desc.description.items);

                    try comment.appendSlice("\n\n");
                }

                if (events.since) |since| {
                    try comment.appendSlice("## since\n\n");
                    try comment.writer().print("{}", .{since});

                    try comment.appendSlice("\n\n");
                }

                if (events.deprecated_since) |deprecated_since| {
                    try comment.appendSlice("## deprecated since\n\n");
                    try comment.writer().print("{}", .{deprecated_since});

                    try comment.appendSlice("\n\n");
                }
                try writeDocComment(writer, comment.items);
            }

            try writer.writeAll("pub fn next");

            try writeCammelCase(events.name.items, writer);

            try writer.writeAll("(self: *const ");

            try writeHumpCase(interface.name.items, writer);

            try writer.writeAll(") void");

            tab_writer.indent += 1;

            try writer.writeAll("{\n");

            try writer.writeAll("_ = self;\n");

            tab_writer.indent -= 1;

            try writer.writeAll("\n}\n");
        }

        tab_writer.indent -= 1;

        try writer.writeAll("\n};\n");
    }

    tab_writer.indent -= 1;

    try writer.writeAll("};\n");
}

fn writeDocComment(writer: writers.TabWriter(std.fs.File.Writer).Writer, comment: []const u8) !void {
    if (comment.len == 0) {
        try writer.writeAll("\n");
        return;
    }

    try writer.writeAll("\n/// ");
    var i: usize = 0;
    while (i < comment.len and std.ascii.isWhitespace(comment[i])) {
        i += 1;
    }

    while (i < comment.len) {
        defer i += 1;
        switch (comment[i]) {
            '\t' => {},
            '\n' => {
                try writer.writeAll("\n/// ");
                i += 1;
                while (i < comment.len and (std.ascii.isWhitespace(comment[i]) and comment[i] != '\n')) {
                    i += 1;
                }
                i -= 1;
            },
            else => |c| {
                try writer.writeByte(c);

                var all_whitespace = true;
                var j: usize = i + 1;

                while (j < comment.len) {
                    if (!std.ascii.isWhitespace(comment[j])) {
                        all_whitespace = false;
                        break;
                    }

                    j += 1;
                }

                if (all_whitespace) {
                    break;
                }
            },
        }
    }
    try writer.writeByte('\n');
}

fn escapeIdentifier(writer: writers.TabWriter(std.fs.File.Writer).Writer, ident: []const u8) !void {
    if (std.ascii.isDigit(ident[0])) {
        try writer.writeAll("@\"");
        try writer.writeAll(ident);
        try writer.writeAll("\"");
    } else {
        try writer.writeAll(ident);
    }
}

pub fn writeHumpCase(text: []const u8, writer: writers.TabWriter(std.fs.File.Writer).Writer) !void {
    var i: usize = 0;

    while (i < text.len) {
        if (i == 0) {
            try writer.writeByte(std.ascii.toUpper(text[i]));
            i += 1;
        } else if (text[i] == '_' and i != text.len - 1) {
            try writer.writeByte(std.ascii.toUpper(text[i + 1]));
            i += 2;
        } else {
            try writer.writeByte(text[i]);
            i += 1;
        }
    }
}

pub fn writeCammelCase(text: []const u8, writer: writers.TabWriter(std.fs.File.Writer).Writer) !void {
    var i: usize = 0;

    while (i < text.len) {
        if (text[i] == '_' and i != text.len - 1) {
            try writer.writeByte(std.ascii.toUpper(text[i + 1]));
            i += 2;
        } else {
            try writer.writeByte(text[i]);
            i += 1;
        }
    }
}
