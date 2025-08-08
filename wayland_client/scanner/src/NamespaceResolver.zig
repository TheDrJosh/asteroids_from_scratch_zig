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
        var iter2 = p.value_ptr.interfaces.iterator();

        while (iter2.next()) |i| {
            for (i.value_ptr.enums.items) |e| {
                e.name.deinit();
            }

            i.value_ptr.enums.deinit();
        }
        p.value_ptr.interfaces.deinit();
    }

    self.protocols.deinit();
}

pub fn registerProtocol(self: *NamespaceResolver, protocol: wayland.Protocol) !void {
    try self.protocols.put(protocol.name.items, Protocol{
        .interfaces = std.StringArrayHashMap(Interface).init(self.allocator),
    });

    const protocol_ptr = self.protocols.getPtr(protocol.name.items).?;

    for (protocol.interfaces.items) |interface| {
        try protocol_ptr.interfaces.put(interface.name.items, Interface{
            .enums = std.ArrayList(Enum).init(self.allocator),
        });

        const interface_ptr = protocol_ptr.interfaces.getPtr(interface.name.items).?;

        for (interface_ptr.enums.items) |@"enum"| {
            var e = Enum{
                .name = try std.ArrayList(u8).initCapacity(self.allocator, @"enum".name.items.len),
            };
            errdefer e.name.deinit();
            try e.name.appendSlice(@"enum".name.items);

            try interface_ptr.enums.append(e);
        }
    }
}

pub fn writeResolvedInterface(
    self: *const NamespaceResolver,
    writer: writers.TabWriter(std.fs.File.Writer).Writer,
    // current_protocol: []const u8,
    name: []const u8,
) !void {
    var iter = self.protocols.iterator();

    l: while (iter.next()) |proto| {
        // if (std.mem.eql(u8, proto.key_ptr, current_protocol)) {
        //     continue;
        // }
        for (proto.value_ptr.interfaces.keys()) |interface| {
            if (std.mem.eql(u8, interface, name)) {
                try writer.writeAll(proto.key_ptr.*);
                try writer.writeByte('.');
                break :l;
            }
        }
    }

    try utils.writePascalCase(name, writer);
}

pub fn writeResolvedEnum(
    self: *const NamespaceResolver,
    writer: writers.TabWriter(std.fs.File.Writer).Writer,
    name: []const u8,
) !void {
    if (std.mem.indexOf(u8, name, ".")) |index| {
        try self.writeResolvedInterface(writer, name[0..index]);
        try writer.writeByte('.');
        try utils.writePascalCase(name[(index + 1)..], writer);
    } else {
        try utils.writePascalCase(name, writer);
    }
}

const Protocol = struct {
    interfaces: std.StringArrayHashMap(Interface),
};

const Interface = struct {
    enums: std.ArrayList(Enum),
};

const Enum = struct {
    name: std.ArrayList(u8),
};
