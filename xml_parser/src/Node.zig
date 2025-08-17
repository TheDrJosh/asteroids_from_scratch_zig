const std = @import("std");

const Document = @import("Document.zig");

const Node = @This();

pub const Id = usize;

parent: ?Id,
type: Type,
document: ?*Document,
allocator: std.mem.Allocator,

pub const Type = union(enum) {
    text: []const u8,
    entity: Entity,

    pub const Entity = struct {
        pub const Attrib = struct {
            name: []const u8,
            value: []const u8,
        };

        name: []const u8,
        attribs: []const Attrib,

        pub fn getAttrib(self: *const Entity, name: []const u8) ?[]const u8 {
            for (self.attribs) |a| {
                if (std.mem.eql(u8, a.name, name)) {
                    return a.value;
                }
            }

            return null;
        }
    };
};

pub fn deinit(self: *const Node) void {
    switch (self.type) {
        .text => |t| {
            self.allocator.free(t);
        },
        .entity => |e| {
            for (e.attribs) |attrib| {
                self.allocator.free(attrib.name);
                self.allocator.free(attrib.value);
            }
            self.allocator.free(e.attribs);
            self.allocator.free(e.name);
        },
    }
}

pub fn getId(self: *const Node) Node.Id {
    if (self.document) |doc| {
        return (@intFromPtr(self) - @intFromPtr(doc.nodes.ptr)) / @sizeOf(Node);
    } else {
        @panic("cannot call document funtion on unattached node");
    }
}

pub fn iterateChildren(self: *const Node) Document.ChildrenIterator {
    if (self.document) |doc| {
        return doc.iterateChildren(self.getId());
    } else {
        @panic("cannot call document funtion on unattached node");
    }
}

pub fn findAll(self: *const Node, path: []const u8) Document.FindAllIterator {
    if (self.document) |doc| {
        return doc.findAll(self.getId(), path);
    } else {
        @panic("cannot call document funtion on unattached node");
    }
}

pub fn find(self: *const Node, path: []const u8) ?*const Node {
    if (self.document) |doc| {
        return doc.find(self.getId(), path);
    } else {
        @panic("cannot call document funtion on unattached node");
    }
}

pub fn getText(self: *const Node) !?[]const u8 {
    if (self.document) |doc| {
        return doc.getText(self.getId());
    } else {
        @panic("cannot call document funtion on unattached node");
    }
}
