const std = @import("std");

pub const Node = union(enum) {
    text: Text,
    entity: Entity,

    pub const Id = usize;

    pub const Text = struct {
        parent: ?Id,
        text: []const u8,
        allocator: std.mem.Allocator,

        pub fn deinit(self: *const Text) void {
            self.allocator.free(self.text);
        }
    };

    pub const Entity = struct {
        pub const Attrib = struct {
            name: []const u8,
            value: []const u8,
            allocator: std.mem.Allocator,

            pub fn deinit(self: *const Attrib) void {
                self.allocator.free(self.name);
                self.allocator.free(self.value);
            }
        };

        parent: ?Id,
        name: []const u8,
        attribs: []const Attrib,
        allocator: std.mem.Allocator,

        pub fn deinit(self: *const Entity) void {
            self.allocator.free(self.name);
            for (self.attribs) |attrib| {
                attrib.deinit();
            }
            self.allocator.free(self.attribs);
        }

        pub fn getAttrib(self: *const Entity, name: []const u8) ?[]const u8 {
            for (self.attribs) |a| {
                if (std.mem.eql(u8, a.name, name)) {
                    return a.value;
                }
            }

            return null;
        }
    };

    pub fn deinit(self: *const Node) void {
        switch (self.*) {
            .text => |t| {
                t.deinit();
            },
            .entity => |e| {
                e.deinit();
            },
        }
    }

    pub fn parent(self: *const Node) ?Id {
        return switch (self.*) {
            .text => |t| t.parent,
            .entity => |e| e.parent,
        };
    }
};
