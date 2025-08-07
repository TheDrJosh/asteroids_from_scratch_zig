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
    try writer.writeAll(" = struct {\n");

    for (protocol.interfaces.items) |interface| {
        if (interface.description) |desc| {
            try writeDocComment(writer, desc.description.items);
        }
        try writer.writeAll("pub const ");
        try writer.writeAll(interface.name.items);
        tab_writer.indent += 1;
        try writer.writeAll(" = struct {\n");

        try writer.writeAll("pub const interface = \"");
        try writer.writeAll(interface.name.items);
        try writer.writeAll("\";\npub const version = ");
        try writer.writeAll(interface.version.items);
        try writer.writeAll(";\n");

        try writer.writeAll("\nobject_id: types.ObjectId,\nruntime: *WaylandRuntime,\n");

        for (interface.enums.items) |@"enum"| {
            if (@"enum".description) |desc| {
                try writeDocComment(writer, desc.description.items);
            }
            try writer.writeAll("pub const ");

            var i: usize = 0;

            while (i < @"enum".name.items.len) {
                if (i == 0) {
                    try writer.writeByte(std.ascii.toUpper(@"enum".name.items[i]));
                    i += 1;
                } else if (@"enum".name.items[i] == '_' and i != @"enum".name.items.len - 1) {
                    try writer.writeByte(std.ascii.toUpper(@"enum".name.items[i + 1]));
                    i += 2;
                } else {
                    try writer.writeByte(@"enum".name.items[i]);
                    i += 1;
                }
            }
            tab_writer.indent += 1;

            if (@"enum".bitfield.items) {
                try writer.writeAll(" = struct(u32) {");
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
                        try comment.appendSlice(since.items);

                        try comment.appendSlice("\n\n");
                    }

                    if (entry.deprecated_since) |deprecated_since| {
                        try comment.appendSlice("## deprecated since\n\n");
                        try comment.appendSlice(deprecated_since.items);
                    }

                    try writeDocComment(writer, comment.items);

                    try escapeIdentifier(writer, entry.name.items);
                    try writer.writeAll(" = ");
                    try writer.writeAll(entry.value.items);
                    try writer.writeAll(",");
                }
            }

            tab_writer.indent -= 1;

            try writer.writeAll("\n};\n");
        }

        tab_writer.indent -= 1;

        try writer.writeAll("\n};\n");
    }

    tab_writer.indent -= 1;

    try writer.writeAll("};\n");
}

fn writeDocComment(writer: writers.TabWriter(std.fs.File.Writer).Writer, comment: []const u8) !void {
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

