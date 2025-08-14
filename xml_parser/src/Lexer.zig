const std = @import("std");

const Lexer = @This();

reader: *std.Io.Reader,

inside_tag: bool,

col: usize,
line: usize,

pub fn init(reader: *std.Io.Reader) Lexer {
    return .{
        .reader = reader,
        .inside_tag = false,

        .col = 1,
        .line = 1,
    };
}

pub const Token = enum {
    string,
    identifier,
    text,

    tag_start, // <tag
    tag_end, // >
    tag_close, // </tag>
    tag_end_and_close, // />
    equal, // =
};

pub const Error = error{
    unexpected_character,
};

pub fn next(self: *Lexer, token_writer: *std.Io.Writer) !Token {
    // errdefer std.debug.print("line: {}, col: {}\n", .{ self.line, self.col });

    if (self.inside_tag) {
        return try self.nextTagToken(token_writer);
    } else {
        return try self.nextTextSection(token_writer);
    }
}

fn nextTagToken(self: *Lexer, token_writer: *std.Io.Writer) !Token {
    try self.skipWhitespace();

    switch (try self.takeByte()) {
        '<' => {
            try token_writer.writeByte('<');

            const is_end =
                if (try self.reader.peekByte() == '/') blk: {
                    try token_writer.writeByte('/');
                    self.toss(1);
                    break :blk true;
                } else false;

            if (try self.reader.peekByte() == '?') {
                try token_writer.writeByte('?');
                self.toss(1);
            }

            while (std.ascii.isAlphanumeric(try self.reader.peekByte()) or
                (try self.reader.peekByte() == '-') or
                (try self.reader.peekByte() == '_'))
            {
                try token_writer.writeByte(try self.reader.peekByte());
                self.toss(1);
            }

            if (is_end) {
                if (try self.takeByte() != '>') {
                    return Error.unexpected_character;
                }
                try token_writer.writeByte('>');
                self.inside_tag = false;
            }

            try token_writer.flush();
            return if (is_end) Token.tag_close else Token.tag_start;
        },
        '=' => {
            try token_writer.writeByte('=');
            try token_writer.flush();
            return Token.equal;
        },
        '"' => {
            try token_writer.writeByte('"');

            l: switch (true) {
                true => {
                    const buf = try self.takeDelimiterInclusive('"');

                    self.col += buf.len;
                    try token_writer.writeAll(buf);

                    //TODO check for a odd number of back slashes not just 1
                    if (buf.len >= 2) {
                        if (buf[buf.len - 2] == '\\') {
                            continue :l true;
                        }
                    }
                },
                false => {},
            }

            try token_writer.flush();
            return Token.string;
        },
        '>' => {
            try token_writer.writeByte('>');
            self.inside_tag = false;

            try token_writer.flush();
            return Token.tag_end;
        },
        '/', '?' => |c| {
            try token_writer.writeByte(c);

            if (try self.takeByte() != '>') {
                return Error.unexpected_character;
            }
            try token_writer.writeByte('>');

            self.inside_tag = false;
            try token_writer.flush();
            return Token.tag_end_and_close;
        },
        else => |c| {
            if (std.ascii.isAlphabetic(c)) {
                try token_writer.writeByte(c);

                while (std.ascii.isAlphanumeric(try self.reader.peekByte()) or
                    try self.reader.peekByte() == '-' or
                    try self.reader.peekByte() == '_')
                {
                    try token_writer.writeByte(try self.takeByte());
                }
                try token_writer.flush();
                return Token.identifier;
            } else {
                std.debug.print("c: {c}\n", .{c});
                return Error.unexpected_character;
            }
        },
    }
}

fn nextTextSection(self: *Lexer, token_writer: *std.Io.Writer) !Token {
    l: switch (true) {
        true => {
            const text = try self.takeDelimiterExclusive('<');
            self.reader.seek -= 1;
            try token_writer.writeAll(text);

            if (std.mem.eql(u8, self.reader.peek(4) catch "", "<!--")) {
                self.toss(3);
                while (!std.mem.eql(u8, try self.reader.peek(3), "-->")) {
                    self.toss(1);
                }
                self.toss(3);
                continue :l true;
            }
        },
        false => {},
    }

    try token_writer.flush();
    self.inside_tag = true;
    return Token.text;
}

fn skipWhitespace(self: *Lexer) !void {
    while (true) {
        const c = try self.reader.peekByte();
        if (std.ascii.isWhitespace(c)) {
            self.toss(1);
        } else {
            return;
        }
    }
}

fn toss(self: *Lexer, len: usize) void {
    const text = self.reader.take(len) catch return;
    for (text) |c| {
        if (c == '\n') {
            self.col = 1;
            self.line += 1;
        } else {
            self.col += 1;
        }
    }
}

fn takeByte(self: *Lexer) !u8 {
    const c = try self.reader.takeByte();
    if (c == '\n') {
        self.col = 1;
        self.line += 1;
    } else {
        self.col += 1;
    }
    return c;
}

fn takeDelimiterExclusive(self: *Lexer, delimiter: u8) ![]u8 {
    const text = try self.reader.takeDelimiterExclusive(delimiter);
    for (text) |c| {
        if (c == '\n') {
            self.col = 1;
            self.line += 1;
        } else {
            self.col += 1;
        }
    }
    return text;
}

fn takeDelimiterInclusive(self: *Lexer, delimiter: u8) ![]u8 {
    const text = try self.reader.takeDelimiterInclusive(delimiter);
    for (text) |c| {
        if (c == '\n') {
            self.col = 1;
            self.line += 1;
        } else {
            self.col += 1;
        }
    }
    return text;
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

    var lexer = Lexer.init(&reader);

    var token_contexts = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer token_contexts.deinit();

    _ = try lexer.next(&token_contexts.writer);

    while (lexer.next(&token_contexts.writer) catch |e| if (e == error.EndOfStream) null else return e) |_| {
        // std.debug.print("token(col: {}, line: {}, str: {s}, type: {})\n", .{ lexer.col, lexer.line, token_contexts.getWritten(), token });

        token_contexts.clearRetainingCapacity();
    }
}

// test "test lexer on wayland.xml" {
//     const file = try (try std.fs.openFileAbsolute("/usr/share/wayland/wayland.xml", .{})).readToEndAlloc(std.testing.allocator, std.math.maxInt(usize));
//     defer std.testing.allocator.free(file);

//     var lexer = Lexer.init(file);

//     while (try lexer.next()) |_| {
//         // std.debug.print("token(start: {}, line: {}, str: {s}, type: {})\n", .{ token.start, token.line, token.slice, token.token_type });
//     }
// }

// test "test lexer on xdg-shell.xml" {
//     const file = try (try std.fs.openFileAbsolute("/usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml", .{})).readToEndAlloc(std.testing.allocator, std.math.maxInt(usize));
//     defer std.testing.allocator.free(file);

//     var lexer = Lexer.init(file);

//     while (try lexer.next()) |_| {
//         // std.debug.print("token(start: {}, line: {}, str: {s}, type: {})\n", .{ token.start, token.line, token.slice, token.token_type });
//     }
// }

// test "test lexer on xdg-decoration-unstable-v1.xml" {
//     const file = try (try std.fs.openFileAbsolute("/usr/share/wayland-protocols/unstable/xdg-decoration/xdg-decoration-unstable-v1.xml", .{})).readToEndAlloc(std.testing.allocator, std.math.maxInt(usize));
//     defer std.testing.allocator.free(file);

//     var lexer = Lexer.init(file);

//     while (try lexer.next()) |_| {
//         // std.debug.print("token(start: {}, line: {}, str: {s}, type: {})\n", .{ token.start, token.line, token.slice, token.token_type });
//     }
// }
