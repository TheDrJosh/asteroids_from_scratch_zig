const std = @import("std");

const Node = @This();

pub const Id = usize;

//TODO Make have referance to document
parent: ?Id,
type: Type,
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
