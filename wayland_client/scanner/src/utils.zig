const std = @import("std");
const writers = @import("writers.zig");
const wayland = @import("wayland.zig");

pub fn writeFormatedDocComment(
    writer: writers.TabWriter(std.fs.File.Writer).Writer,
    description: ?wayland.Description,
    alt_summary: ?std.ArrayList(u8),
    version: ?u32,
    since: ?u32,
    deprecated_since: ?u32,
    allocator: std.mem.Allocator,
) !void {
    var comment = std.ArrayList(u8).init(allocator);
    defer comment.deinit();

    if (description) |desc| {
        var all_whitespace = true;
        for (desc.description.items) |c| {
            if (!std.ascii.isWhitespace(c)) {
                all_whitespace = false;
                break;
            }
        }

        if (all_whitespace) {
            try comment.appendSlice(desc.summary.items);
            try comment.appendSlice("\n\n");
        } else {
            // try comment.appendSlice(desc.description.items);
            for (desc.description.items, 0..) |c, i| {
                var remaining_whitespace = true;
                for (desc.description.items[(i)..]) |w| {
                    if (!std.ascii.isWhitespace(w)) {
                        remaining_whitespace = false;
                        break;
                    }
                }
                if (remaining_whitespace) {
                    break;
                }
                try comment.append(c);
            }
            try comment.appendSlice("\n\n");
        }
    } else {
        if (alt_summary) |sum| {
            try comment.appendSlice(sum.items);
            try comment.appendSlice("\n\n");
        }
    }

    if (version) |v| {
        try comment.writer().print("version {}\n\n", .{v});
    }

    if (since) |s| {
        try comment.writer().print("available since version {}\n\n", .{s});
    }

    if (deprecated_since) |ds| {
        try comment.writer().print("deprecated since version {}\n\n", .{ds});
    }

    try writeDocComment(writer, comment.items);
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

pub fn escapeIdentifier(writer: writers.TabWriter(std.fs.File.Writer).Writer, ident: []const u8) !void {
    if (std.ascii.isDigit(ident[0])) {
        try writer.writeAll("@\"");
        try writer.writeAll(ident);
        try writer.writeAll("\"");
        return;
    }
    if (std.mem.eql(u8, ident, "async")) {
        try writer.writeAll("@\"async\"");
        return;
    }
    try writer.writeAll(ident);
}

pub fn writePascalCase(text: []const u8, writer: writers.TabWriter(std.fs.File.Writer).Writer) !void {
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
