const std = @import("std");

const wayland = @import("wayland.zig");

const NamespaceResolver = @This();
const writers = @import("writers.zig");
const utils = @import("utils.zig");

protocols: std.StringArrayHashMap(Protocol),
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) NamespaceResolver {
    return NamespaceResolver{
        .protocols = std.StringArrayHashMap(Protocol).init(allocator),
        .allocator = allocator,
    };
}

pub fn deinit(self: *NamespaceResolver) void {
    var iter = self.protocols.iterator();

    while (iter.next()) |p| {
        for (p.value_ptr.interfaces.items) |i| {
            i.name.deinit();
        }
        p.value_ptr.interfaces.deinit();
    }

    self.protocols.deinit();
}

pub fn registerProtocol(self: *NamespaceResolver, protocol: wayland.Protocol) !void {
    try self.protocols.put(protocol.name.items, Protocol{
        .interfaces = std.array_list.Managed(Interface).init(self.allocator),
    });

    const protocol_ptr = self.protocols.getPtr(protocol.name.items).?;

    for (protocol.interfaces.items) |interface| {
        var name = try std.array_list.Managed(u8).initCapacity(self.allocator, interface.name.items.len);
        name.appendSliceAssumeCapacity(interface.name.items);

        try protocol_ptr.interfaces.append(Interface{
            .name = name,
        });
    }
}

pub fn writeResolvedInterface(
    self: *const NamespaceResolver,
    writer: *std.io.Writer,
    name: []const u8,
) !void {
    var iter = self.protocols.iterator();

    l: while (iter.next()) |proto| {
        for (proto.value_ptr.interfaces.items) |interface| {
            if (std.mem.eql(u8, interface.name.items, name)) {
                try writer.writeAll(proto.key_ptr.*);
                try writer.writeByte('.');
                break :l;
            }
        }
    }

    try utils.writePascalCase(writer, name);
}

pub fn writeResolvedEnum(
    self: *const NamespaceResolver,
    writer: *std.io.Writer,
    name: []const u8,
) !void {
    if (std.mem.indexOf(u8, name, ".")) |index| {
        try self.writeResolvedInterface(writer, name[0..index]);
        try writer.writeByte('.');
        try utils.writePascalCase(writer, name[(index + 1)..]);
    } else {
        try utils.writePascalCase(writer, name);
    }
}

const Protocol = struct {
    interfaces: std.array_list.Managed(Interface),
};

const Interface = struct {
    name: std.array_list.Managed(u8),
};
