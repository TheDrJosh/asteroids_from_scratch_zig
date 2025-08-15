const std = @import("std");

const Parser = @import("Parser.zig");
const Lexer = @import("Lexer.zig");
const Node = @import("Node.zig");

const Document = @This();

nodes: []const Node,
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator, reader: *std.Io.Reader) !Document {
    var parser = Parser.init(allocator, reader);
    defer parser.deinit();

    var nodes = std.array_list.Managed(Node).init(allocator);
    errdefer {
        for (nodes.items) |node| {
            node.deinit();
        }
        nodes.deinit();
    }

    while (parser.next() catch |e| if (e == error.EndOfStream) null else return e) |node| {
        try nodes.append(node);
    }

    return Document{
        .nodes = try nodes.toOwnedSlice(),
        .allocator = allocator,
    };
}

pub fn deinit(self: *const Document) void {
    for (self.nodes) |node| {
        node.deinit();
    }
    self.allocator.free(self.nodes);
}

pub const ChildrenIterator = struct {
    parent_id: Node.Id,
    document: *const Document,
    index: usize,
    pub fn next(self: *ChildrenIterator) ?Node.Id {
        while (self.index < self.document.nodes.len) : (self.index += 1) {
            if (self.document.nodes[self.index].parent() == self.parent_id) {
                return self.index;
            }
        }

        return null;
    }
};

pub fn iterateChildren(self: *const Document, node: Node.Id) ChildrenIterator {
    return .{
        .document = self,
        .index = 0,
        .parent_id = node,
    };
}

pub fn getNode(self: *const Document, node: Node.Id) *const Node {
    return &self.nodes[node];
}

pub const FindAllIterator = struct {
    base_node: ?Node.Id,
    document: *const Document,
    index: usize,
    path: []const u8,

    pub fn next(self: *FindAllIterator) ?Node.Id {
        outer: while (self.index < self.document.nodes.len) {
            defer self.index += 1;
            switch (self.document.nodes[self.index].type) {
                .entity => {
                    var path_iter = std.mem.splitBackwardsScalar(u8, self.path, '/');

                    var current: ?usize = self.index;

                    while (path_iter.next()) |path_part| {
                        if (std.mem.eql(u8, self.document.nodes[current orelse continue :outer].type.entity.name, path_part)) {
                            current = self.document.nodes[self.index].parent;
                        } else {
                            continue :outer;
                        }
                    }
                    if (current == self.base_node) {
                        return self.index;
                    }
                },
                else => {},
            }
        }

        return null;
    }
};

pub fn findAll(self: *const Document, base_node: ?Node.Id, path: []const u8) FindAllIterator {
    return .{
        .base_node = base_node,
        .document = self,
        .index = 0,
        .path = path,
    };
}

pub fn find(self: *const Document, base_node: ?Node.Id, path: []const u8) ?Node.Id {
    var iter = self.findAll(base_node, path);
    return iter.next();
}

pub fn getText(self: *const Document, node: Node.Id) !?[]const u8 {
    switch (self.nodes[node].type) {
        .entity => {
            var text_child: ?[]const u8 = null;

            for (self.nodes) |n| {
                if (n.parent == node) {
                    switch (n.type) {
                        .entity => {
                            return error.node_has_extra_children;
                        },
                        .text => |t| {
                            if (text_child == null) {
                                text_child = t;
                            } else {
                                return error.node_has_extra_children;
                            }
                        },
                    }
                }
            }
            return text_child;
        },
        .text => |text| {
            return text;
        },
    }
}

test {
    @import("std").testing.refAllDecls(@This());
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

    var doc = try Document.init(std.testing.allocator, &reader);
    defer doc.deinit();

    const to = doc.find(null, "note/to") orelse return error.expected_not_null;
    try std.testing.expectEqualStrings("Tove", try doc.getText(to) orelse return error.expected_not_null);

    const from = doc.find(null, "note/from") orelse return error.expected_not_null;
    try std.testing.expectEqualStrings("Jani", try doc.getText(from) orelse return error.expected_not_null);

    const heading = doc.find(null, "note/heading") orelse return error.expected_not_null;
    try std.testing.expectEqualStrings("Reminder", try doc.getText(heading) orelse return error.expected_not_null);

    const body = doc.find(null, "note/body") orelse return error.expected_not_null;
    try std.testing.expectEqualStrings("Don't forget me this weekend!", try doc.getText(body) orelse return error.expected_not_null);
}
