const std = @import("std");

const Node = @This();

pub const Child = union(enum) {
    node: *Node,
    text: []const u8,
};

pub const Attrib = struct {
    name: []const u8,
    value: []const u8,
};

name: []const u8,
attribs: []const Attrib,
parent: ?*Node,
children: []const Child,

pub fn getAttrib(self: *Node, name: []const u8) ?[]const u8 {
    for (self.attribs) |a| {
        if (std.mem.eql(u8, a.name, name)) {
            return a.value;
        }
    }

    return null;
}

pub fn find(self: *Node, path: []const u8) ?*Node {
    const slash_index = std.mem.indexOf(u8, path, "/");

    const name = if (slash_index) |index| path[0..index] else path;

    for (self.children) |child| {
        switch (child) {
            .node => |node| {
                if (std.mem.eql(u8, node.name, name)) {
                    if (slash_index) |i| {
                        return node.find(path[(i + 1)..]);
                    } else {
                        return node;
                    }
                }
            },
            .text => {},
        }
    }

    return null;
}

pub const Iterator = struct {
    index: usize,
    inner_iter: ?*Iterator,
    node: *Node,
    path: []const u8,
    allocator: std.mem.Allocator,

    pub fn next(self: *Iterator) !?*Node {
        if (self.inner_iter) |iter| {
            if (try iter.next()) |n| {
                return n;
            } else {
                iter.deinit();
                self.inner_iter = null;
            }
        }

        const slash_index = std.mem.indexOf(u8, self.path, "/");

        const name = if (slash_index) |index| self.path[0..index] else self.path;

        while (self.index < self.node.children.len) {
            defer self.index += 1;
            switch (self.node.children[self.index]) {
                .node => |node| {
                    if (std.mem.eql(u8, node.name, name)) {
                        if (slash_index) |i| {
                            const iter = try self.allocator.create(Iterator);
                            iter.* = node.findAll(self.path[(i + 1)..], self.allocator);
                            self.inner_iter = iter;

                            return try iter.next();
                        } else {
                            return node;
                        }
                    }
                },
                .text => {},
            }
        }

        return null;
    }

    pub fn deinit(self: *const Iterator) void {
        if (self.inner_iter) |iter| {
            iter.deinit();
            self.allocator.destroy(iter);
        }
    }
};

pub fn findAll(self: *Node, path: []const u8, allocator: std.mem.Allocator) Iterator {
    return Iterator{
        .index = 0,
        .inner_iter = null,
        .node = self,
        .path = path,
        .allocator = allocator,
    };
}

pub const TextIterator = struct {
    index: usize,
    node: *Node,

    pub fn next(self: *TextIterator) ?[]const u8 {
        while (self.index < self.node.children.len) {
            defer self.index += 1;
            switch (self.node.children[self.index]) {
                .node => {},
                .text => |str| {
                    return str;
                },
            }
        }
        return null;
    }
};

pub fn text(self: *Node) TextIterator {
    return .{
        .index = 0,
        .node = self,
    };
}
