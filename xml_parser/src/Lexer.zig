const std = @import("std");

const Node = @import("Node.zig");

const Lexer = @This();

current: usize,
xml_string: []const u8,
line: usize,

inside_tag: bool,

prev: ?Token,

pub fn init(xml_string: []const u8) Lexer {
    return .{
        .current = 0,
        .xml_string = xml_string,
        .line = 1,

        .inside_tag = false,
        .prev = null,
    };
}

pub const Token = struct {
    pub const Type = enum {
        string,
        identifier,
        text,

        tag_start, // <tag
        tag_end, // >
        tag_close, // </tag>
        tag_end_and_close, // />
        equal, // =
    };

    start: usize,
    slice: []const u8,
    line: usize,

    token_type: Type,
};

pub const Error = error{
    unexpected_eof,
    unexpected_character,
};

pub fn next(self: *Lexer) Error!?Token {
    const t = try self.inner_next();
    // if (t) |tt| {
    //     std.debug.print("token: {}\n", .{tt.token_type});
    // }
    self.prev = t;
    return t;
}

fn inner_next(self: *Lexer) Error!?Token {
    errdefer {
        std.debug.print("Lexer Error current: {}, line: {}", .{ self.current, self.line });
    }
    const start = self.current;
    const line = self.line;

    if (self.inside_tag) {
        self.skipWhitespace();

        switch (self.advance() orelse return null) {
            '=' => {
                return Token{
                    .start = start,
                    .line = line,
                    .slice = self.xml_string[start..self.current],
                    .token_type = .equal,
                };
            },
            '"' => {
                while (!((self.advance() orelse return Error.unexpected_eof) == '"' and self.xml_string[self.current - 2] != '\\')) {}
                return Token{
                    .start = start,
                    .line = line,
                    .slice = self.xml_string[start..self.current],
                    .token_type = .string,
                };
            },
            '>' => {
                self.inside_tag = false;

                return Token{
                    .start = start,
                    .line = line,
                    .slice = self.xml_string[start..self.current],
                    .token_type = .tag_end,
                };
            },
            '/', '?' => {
                if ((self.advance() orelse return Error.unexpected_eof) != '>') {
                    return Error.unexpected_character;
                }

                self.inside_tag = false;

                return Token{
                    .start = start,
                    .line = line,
                    .slice = self.xml_string[start..self.current],
                    .token_type = .tag_end_and_close,
                };
            },
            else => |c| {
                if (std.ascii.isAlphabetic(c)) {
                    while ((std.ascii.isAlphanumeric(self.peek() orelse return Error.unexpected_eof) or self.peek() == '-' or self.peek() == '_')) {
                        _ = self.advance();
                    }

                    return Token{
                        .start = start,
                        .line = line,
                        .slice = self.xml_string[start..self.current],
                        .token_type = .identifier,
                    };
                } else {
                    return Error.unexpected_character;
                }
            },
        }
    } else {
        if ((self.advance() orelse return null) == '<') {
            const is_end = switch (self.advance() orelse 0) {
                '/' => true,
                '!' => {
                    if ((self.advance() orelse return Error.unexpected_eof) != '-') {
                        return Error.unexpected_character;
                    }

                    if ((self.advance() orelse return Error.unexpected_eof) != '-') {
                        return Error.unexpected_character;
                    }

                    while (!((self.advance() orelse return null) == '>' and self.xml_string[self.current - 2] == '-' and self.xml_string[self.current - 3] == '-')) {
                        if (self.xml_string[self.current - 1] == '\n') {
                            self.line += 1;
                        }
                    }

                    return try self.next();
                },
                else => false,
            };

            while (std.ascii.isAlphanumeric(self.peek() orelse 0)) {
                _ = self.advance();
            }

            if (is_end) {
                if ((self.advance() orelse return Error.unexpected_eof) != '>') {
                    return Error.unexpected_character;
                }
            } else {
                self.inside_tag = true;
            }

            return Token{
                .start = start,
                .line = line,
                .slice = self.xml_string[start..self.current],
                .token_type = if (is_end) .tag_close else .tag_start,
            };
        } else {
            var all_whitespace = true;
            while ((self.peek() orelse return null) != '<') {
                if (all_whitespace and !std.ascii.isWhitespace(self.peek() orelse 0)) {
                    all_whitespace = false;
                }
                if (self.advance() == '\n') {
                    self.line += 1;
                }
            }

            if (all_whitespace) {
                return try self.next();
            }

            return Token{
                .start = start,
                .line = line,
                .slice = self.xml_string[start..self.current],
                .token_type = .text,
            };
        }
    }
}

fn peek(self: *const Lexer) ?u8 {
    if (self.current >= self.xml_string.len) {
        return null;
    }
    return self.xml_string[self.current];
}

fn advance(self: *Lexer) ?u8 {
    if (self.peek() == '\n') {
        self.line += 1;
    }
    if (self.current >= self.xml_string.len) {
        return null;
    }

    self.current += 1;

    return self.xml_string[self.current - 1];
}

fn skipWhitespace(self: *Lexer) void {
    while (true) {
        if (std.ascii.isWhitespace(self.peek() orelse 0)) {
            _ = self.advance();
        } else {
            return;
        }
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
