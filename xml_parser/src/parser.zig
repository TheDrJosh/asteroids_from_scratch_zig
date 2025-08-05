const std = @import("std");

const Node = @import("Node.zig");

const Lexer = @import("Lexer.zig");

pub const Error = error{
    unexpected_end_of_tokens,
    unexpected_token,
    miss_matched_start_and_end_tags,
    unknown_entity,
    unknown_escape_sequence,
};

pub fn parse(lexer: *Lexer, allocator: std.mem.Allocator) !*Node {
    errdefer {
        if (lexer.prev) |prev| {
            std.debug.print("Parse Error:\n\tstart: {}\n\tline: {}\n\tslice: {s}\n\ttype: {}\n", .{ prev.start, prev.line, prev.slice, prev.token_type });
        }
    }
    return try parseInner(lexer, allocator, null);
}

fn parseInner(lexer: *Lexer, allocator: std.mem.Allocator, parent: ?*Node) !*Node {
    var tag = try parseTag(lexer, allocator);

    // std.debug.print("Tag Info:\n\tname: {s}\n\tclosed: {}\n\tattribs:\n", .{ tag.name, tag.closed });
    // for (tag.attribs.items) |attrib| {
    //     std.debug.print("\t\t{s}: {s}\n", .{ attrib.name, attrib.value });
    // }

    if (tag.closed) {
        const node = try allocator.create(Node);

        node.name = tag.name;
        node.attribs = try tag.attribs.toOwnedSlice();
        node.parent = parent;
        node.children = try allocator.alloc(Node.Child, 0);

        return node;
    } else {
        var children = std.ArrayList(Node.Child).init(allocator);
        errdefer children.deinit();
        const node = try allocator.create(Node);
        errdefer allocator.destroy(node);

        while (true) {
            const current = lexer.current;
            const line = lexer.line;

            const inside_tag = lexer.inside_tag;

            const token = try lexer.next() orelse return Error.unexpected_end_of_tokens;

            switch (token.token_type) {
                .text => {
                    var text = std.ArrayList(u8).init(allocator);
                    errdefer text.deinit();

                    var text_stream = std.io.fixedBufferStream(token.slice);
                    const text_reader = text_stream.reader();

                    while (text_reader.readByte() catch null) |c| {
                        if (c == '&') {
                            const entity = try text_reader.readUntilDelimiterAlloc(allocator, ';', std.math.maxInt(usize));
                            defer allocator.free(entity);

                            if (std.mem.eql(u8, entity, "lt")) {
                                try text.append('<');
                            } else if (std.mem.eql(u8, entity, "gt")) {
                                try text.append('>');
                            } else if (std.mem.eql(u8, entity, "amp")) {
                                try text.append('&');
                            } else if (std.mem.eql(u8, entity, "apos")) {
                                try text.append('\'');
                            } else if (std.mem.eql(u8, entity, "quot")) {
                                try text.append('"');
                            } else {
                                return Error.unknown_entity;
                            }
                        } else {
                            try text.append(c);
                        }
                    }

                    try children.append(Node.Child{ .text = try text.toOwnedSlice() });
                },
                .tag_start => {
                    lexer.current = current;
                    lexer.line = line;
                    lexer.inside_tag = inside_tag;

                    const child = try parseInner(lexer, allocator, node);

                    try children.append(.{ .node = child });
                },
                .tag_close => {
                    if (!std.mem.eql(u8, tag.name, token.slice[2..(token.slice.len - 1)])) {
                        return Error.miss_matched_start_and_end_tags;
                    }

                    node.name = tag.name;
                    node.attribs = try tag.attribs.toOwnedSlice();
                    node.parent = parent;
                    node.children = try children.toOwnedSlice();

                    return node;
                },
                else => return Error.unexpected_token,
            }
        }
    }
}

const TagInfo = struct {
    name: []const u8,
    attribs: std.ArrayList(Node.Attrib),
    closed: bool,
};

fn parseTag(lexer: *Lexer, allocator: std.mem.Allocator) !TagInfo {
    const open = try expectNext(lexer, .tag_start);

    const name = try allocator.alloc(u8, open.slice.len - 1);
    errdefer allocator.free(name);

    @memcpy(name, open.slice[1..]);

    var attribs = std.ArrayList(Node.Attrib).init(allocator);
    errdefer attribs.deinit();

    while (true) {
        const token = try lexer.next() orelse return Error.unexpected_end_of_tokens;

        switch (token.token_type) {
            .identifier => {
                _ = try expectNext(lexer, .equal);

                const string = try expectNext(lexer, .string);

                var text = std.ArrayList(u8).init(allocator);
                errdefer text.deinit();

                var text_stream = std.io.fixedBufferStream(string.slice[1..(string.slice.len - 1)]);
                const text_reader = text_stream.reader();

                while (text_reader.readByte() catch null) |c| {
                    if (c == '\\') {
                        switch (try text_reader.readByte()) {
                            'n' => try text.append('\n'),
                            'r' => try text.append('\r'),
                            '\t' => try text.append('\t'),
                            '\\' => try text.append('\\'),
                            '\'' => try text.append('\''),
                            '\"' => try text.append('"'),
                            else => return Error.unknown_escape_sequence,
                        }
                    } else {
                        try text.append(c);
                    }
                }

                try attribs.append(.{ .name = token.slice, .value = try text.toOwnedSlice() });
            },
            .tag_end => {
                return TagInfo{
                    .name = name,
                    .attribs = attribs,
                    .closed = false,
                };
            },
            .tag_end_and_close => {
                return TagInfo{
                    .name = name,
                    .attribs = attribs,
                    .closed = true,
                };
            },
            else => return Error.unexpected_token,
        }
    }
}

fn expectNext(lexer: *Lexer, token_type: Lexer.Token.Type) !Lexer.Token {
    const token = try lexer.next() orelse return Error.unexpected_end_of_tokens;

    if (token.token_type != token_type) {
        return Error.unexpected_token;
    }

    return token;
}

// test {
//     const file = try (try std.fs.openFileAbsolute("/usr/share/wayland/wayland.xml", .{})).readToEndAlloc(std.testing.allocator, std.math.maxInt(usize));
//     defer std.testing.allocator.free(file);

//     var lexer = Lexer.init(file);

//     var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
//     const allocator = arena.allocator();
//     defer arena.deinit();

//     const node = try parse(&lexer, allocator);

//     std.debug.print("node: {any}\n", .{node});

//     const node2 = try parse(&lexer, allocator);

//     std.debug.print("node: {any}\n", .{node2});
// }
