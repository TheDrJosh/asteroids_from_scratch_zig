const std = @import("std");
const wayland = @import("../wayland.zig");
const TabWriter = @import("../writers.zig").TabWriter;
const utils = @import("../utils.zig");
const NamespaceResolver = @import("../NamespaceResolver.zig");

pub fn processEvents(tab_writer: *TabWriter, interface: wayland.Interface, resolver: NamespaceResolver, allocator: std.mem.Allocator) !void {
    const writer = &tab_writer.interface;

    for (interface.events.items, 0..) |event, opcode| {
        try utils.writeFormatedDocComment(
            writer,
            event.description,
            null,
            null,
            event.since,
            event.deprecated_since,
            allocator,
        );

        try writer.writeAll("pub const ");
        try utils.writePascalCase(writer, event.name.items);
        try writer.writeAll("Event = ");

        tab_writer.indent += 1;
        try writer.writeAll("struct {");

        for (event.args.items) |arg| {
            try utils.writeFormatedDocComment(
                writer,
                arg.description,
                arg.summary,
                null,
                null,
                null,
                allocator,
            );
            try writer.print("{s}: ", .{arg.name.items});

            switch (arg.type) {
                .int => {
                    if (arg.@"enum") |e| {
                        try resolver.writeResolvedEnum(writer, e.items);
                    } else {
                        try writer.writeAll("i32");
                    }
                },
                .uint => {
                    if (arg.@"enum") |e| {
                        try resolver.writeResolvedEnum(writer, e.items);
                    } else {
                        try writer.writeAll("u32");
                    }
                },
                .fixed => {
                    try writer.writeAll("wayland_client.types.Fixed");
                },
                .string => {
                    try writer.writeAll("wayland_client.types.String");
                },
                .object => {
                    if (arg.allow_null) {
                        try writer.writeAll("?");
                    }

                    if (arg.interface) |inter| {
                        try resolver.writeResolvedInterface(writer, inter.items);
                    } else {
                        try writer.writeAll("wayland_client.types.ObjectId");
                    }
                },
                .new_id => {
                    if (arg.interface) |inter| {
                        try resolver.writeResolvedInterface(writer, inter.items);
                    } else {
                        try writer.writeAll("wayland_client.types.ObjectId");
                    }
                },
                .array => {
                    try writer.writeAll("std.array_list.Managed(u8)");
                },
                .fd => {
                    try writer.writeAll("wayland_client.types.Fd");
                },
            }
            try writer.writeAll(",");
        }

        try writer.print("\npub const opcode = {};", .{opcode});

        tab_writer.indent -= 1;
        try writer.writeAll("\n};");

        try writer.flush();

        try utils.writeFormatedDocComment(
            writer,
            event.description,
            null,
            null,
            event.since,
            event.deprecated_since,
            allocator,
        );

        try writer.writeAll("pub fn next");

        try utils.writePascalCase(writer, event.name.items);

        try writer.writeAll("(self: *const ");

        try utils.writePascalCase(writer, interface.name.items);

        try writer.writeAll(") !");

        if (event.args.items.len == 0) {
            try writer.writeAll("bool");
        } else {
            try writer.writeAll("?");
            try utils.writePascalCase(writer, event.name.items);
            try writer.writeAll("Event");
        }

        tab_writer.indent += 1;

        try writer.writeAll(" {\n");

        try writer.writeAll("return (try self.runtime.next(&[1]type{");
        try utils.writePascalCase(writer, event.name.items);
        try writer.writeAll("Event}, [1]wayland_client.types.ObjectId{self.object_id})");

        if (event.args.items.len == 0) {
            try writer.writeAll(") != null;");
        } else {
            try writer.writeAll(" orelse return null).@\"0\";");
        }

        tab_writer.indent -= 1;

        try writer.writeAll("\n}");
    }
}
