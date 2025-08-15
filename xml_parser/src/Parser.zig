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

const Parser = @This();

const Parent = struct {
    id: usize,
    name: []const u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *const Parent) void {
        self.allocator.free(self.name);
    }
};

lexer: Lexer,
parents: std.array_list.Managed(Parent),
current_id: usize,
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator, reader: *std.io.Reader) Parser {
    return Parser{
        .lexer = Lexer.init(reader),
        .allocator = allocator,
        .current_id = 0,
        .parents = std.array_list.Managed(Parent).init(allocator),
    };
}

pub fn deinit(self: *const Parser) void {
    for (self.parents.items) |p| {
        p.deinit();
    }
    self.parents.deinit();
}

pub fn next(self: *Parser) !Node {
    var token_text = std.Io.Writer.Allocating.init(self.allocator);
    defer token_text.deinit();

    s: switch (try self.lexer.next(&token_text.writer)) {
        .tag_start => {
            const name = try self.allocator.alloc(u8, token_text.getWritten().len - 1);
            errdefer self.allocator.free(name);

            @memcpy(name, token_text.getWritten()[1..]);
            token_text.clearRetainingCapacity();

            var tag_info = try self.parseTagInfo();
            errdefer tag_info.deinit();

            const parent_id = if (self.parents.getLastOrNull()) |p| p.id else null;

            if (!tag_info.self_closed) {
                const pname = try self.allocator.alloc(u8, name.len);
                errdefer self.allocator.free(pname);
                @memcpy(pname, name);

                try self.parents.append(Parent{
                    .id = self.current_id,
                    .name = pname,
                    .allocator = self.allocator,
                });
            }

            self.current_id += 1;

            return Node{
                .parent = parent_id,
                .allocator = self.allocator,
                .type = .{
                    .entity = .{
                        .attribs = try tag_info.attribs.toOwnedSlice(),
                        .name = name,
                    },
                },
            };
        },
        .tag_close => {
            const entity = self.parents.pop() orelse return error.unexpected_token;
            defer entity.deinit();
            if (!std.mem.eql(u8, token_text.getWritten()[2..(token_text.getWritten().len - 1)], entity.name)) {
                return error.unexpected_token;
            }
            token_text.clearRetainingCapacity();
            continue :s try self.lexer.next(&token_text.writer);
        },
        .text => {
            for (token_text.getWritten()) |c| {
                if (!std.ascii.isWhitespace(c)) {
                    const parent_id = if (self.parents.getLastOrNull()) |p| p.id else null;

                    self.current_id += 1;
                    return .{
                        .allocator = self.allocator,
                        .parent = parent_id,
                        .type = .{
                            .text = try token_text.toOwnedSlice(),
                        },
                    };
                }
            }
            token_text.clearRetainingCapacity();
            continue :s try self.lexer.next(&token_text.writer);
        },
        else => return Error.unexpected_token,
    }
}

const TagInfo = struct {
    attribs: std.array_list.Managed(Node.Type.Entity.Attrib),
    self_closed: bool,
    pub fn deinit(self: *const TagInfo) void {
        for (self.attribs.items) |attrib| {
            self.attribs.allocator.free(attrib.name);
            self.attribs.allocator.free(attrib.value);
        }
        self.attribs.deinit();
    }
};

pub fn parseTagInfo(self: *Parser) !TagInfo {
    var token_text = std.Io.Writer.Allocating.init(self.allocator);
    defer token_text.deinit();

    var attribs = std.array_list.Managed(Node.Type.Entity.Attrib).init(self.allocator);
    errdefer attribs.deinit();

    state: switch (try self.lexer.next(&token_text.writer)) {
        .identifier => {
            const name = try token_text.toOwnedSlice();
            errdefer self.allocator.free(name);

            var buf: [8]u8 = undefined;
            var dw = std.Io.Writer.Discarding.init(&buf);
            try self.expectNext(.equal, &dw.writer);

            try self.expectNext(.string, &token_text.writer);

            var text = std.Io.Writer.Allocating.init(self.allocator);
            defer text.deinit();

            var text_reader = std.Io.Reader.fixed(token_text.getWritten()[1..(token_text.getWritten().len - 1)]);

            while ((text_reader.streamDelimiter(&text.writer, '\\') catch |e| if (e == error.EndOfStream) 0 else return e) != 0) {
                switch (try text_reader.takeByte()) {
                    'n' => try text.writer.writeByte('\n'),
                    'r' => try text.writer.writeByte('\r'),
                    '\t' => try text.writer.writeByte('\t'),
                    '\\' => try text.writer.writeByte('\\'),
                    '\'' => try text.writer.writeByte('\''),
                    '\"' => try text.writer.writeByte('"'),
                    else => return Error.unknown_escape_sequence,
                }
            }

            try attribs.append(.{
                .name = name,
                .value = try text.toOwnedSlice(),
            });

            token_text.clearRetainingCapacity();

            continue :state try self.lexer.next(&token_text.writer);
        },
        .tag_end => {
            return TagInfo{
                .attribs = attribs,
                .self_closed = false,
            };
        },
        .tag_end_and_close => {
            return TagInfo{
                .attribs = attribs,
                .self_closed = true,
            };
        },
        else => return Error.unexpected_token,
    }
}

fn expectNext(self: *Parser, token_type: Lexer.Token, token_writer: *std.Io.Writer) !void {
    const token = try self.lexer.next(token_writer);

    if (token != token_type) {
        return Error.unexpected_token;
    }
}

test {
    const text =
        \\<note>
        \\  <to>Tove</to>
        \\  <from>Jani</from>
        \\  <heading>Reminder</heading>
        \\  <body>Don't forget me this weekend!</body>
        \\</note>
    ;
    var reader = std.Io.Reader.fixed(text);

    var parser = Parser.init(std.testing.allocator, &reader);
    defer parser.deinit();

    // var i: usize = 0;
    while (parser.next() catch |e| if (e == error.EndOfStream) null else return e) |node| {
        defer node.deinit();
        // std.debug.print("node({}): {any}\n", .{ i, node });
        // i += 1;
    }
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
