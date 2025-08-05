const std = @import("std");

const parser = @import("parser.zig");
const Lexer = @import("Lexer.zig");
const Node = @import("Node.zig");

const Document = @This();

root: *Node,
arena_allocator: std.heap.ArenaAllocator,

pub fn init(xml_string: []const u8, allocator: std.mem.Allocator) !Document {
    var arena = std.heap.ArenaAllocator.init(allocator);
    const alloc = arena.allocator();

    var lexer = Lexer.init(xml_string);

    const prolog_or_root = try parser.parse(&lexer, alloc);

    const root = if (std.mem.eql(u8, prolog_or_root.name, "?xml")) try parser.parse(&lexer, alloc) else prolog_or_root;

    return Document{
        .root = root,
        .arena_allocator = arena,
    };
}

pub fn deinit(self: *const Document) void {
    self.arena_allocator.deinit();
}

// test {
//     const file = try (try std.fs.openFileAbsolute("/usr/share/wayland/wayland.xml", .{})).readToEndAlloc(std.testing.allocator, std.math.maxInt(usize));
//     defer std.testing.allocator.free(file);

//     const doc = try Document.init(file, std.testing.allocator);
//     defer doc.deinit();

//     std.debug.print("node: {any}\n", .{doc.root});
// }
