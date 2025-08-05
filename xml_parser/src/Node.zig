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

