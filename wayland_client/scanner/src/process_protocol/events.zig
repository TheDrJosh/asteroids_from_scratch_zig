const std = @import("std");
const wayland = @import("../wayland.zig");
const TabWriter = @import("../writers.zig").TabWriter;
const utils = @import("../utils.zig");
const NamespaceResolver = @import("../NamespaceResolver.zig");

pub fn processEvents(tab_writer: *TabWriter(std.fs.File.Writer), interface: wayland.Interface, resolver: NamespaceResolver, allocator: std.mem.Allocator) !void {
    const writer = tab_writer.writer();

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

        try writer.writeAll("pub fn next");

        try utils.writePascalCase(event.name.items, writer);

        try writer.writeAll("(self: *const ");

        try utils.writePascalCase(interface.name.items, writer);

        try writer.writeAll(") !");

        if (event.args.items.len == 0) {
            try writer.writeAll("bool");
        } else {
            tab_writer.indent += 1;
            try writer.writeAll("?struct {");

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
                        try writer.writeAll("types.Fixed");
                    },
                    .string => {
                        try writer.writeAll("types.String");
                    },
                    .object => {
                        if (arg.allow_null) {
                            try writer.writeAll("?");
                        }

                        if (arg.interface) |inter| {
                            try resolver.writeResolvedInterface(writer, inter.items);
                        } else {
                            try writer.writeAll("types.ObjectId");
                        }
                    },
                    .new_id => {
                        if (arg.interface) |inter| {
                            try resolver.writeResolvedInterface(writer, inter.items);
                        } else {
                            try writer.writeAll("types.ObjectId");
                        }
                    },
                    .array => {
                        try writer.writeAll("std.Arraylist(u8)");
                    },
                    .fd => {
                        try writer.writeAll("types.Fd");
                    },
                }
                try writer.writeAll(",");
            }

            tab_writer.indent -= 1;
            try writer.writeAll("\n}");
        }

        tab_writer.indent += 1;

        try writer.writeAll(" {\n");

        if (event.args.items.len == 0) {
            try writer.print("return (try self.runtime.next(self.object_id, {}, struct {{}})) != null;", .{opcode});
        } else {
            try writer.print("return try self.runtime.next(self.object_id, {}, @typeInfo(@typeInfo(@typeInfo(@TypeOf(next", .{opcode});
            try utils.writePascalCase(event.name.items, writer);
            try writer.writeAll(")).@\"fn\".return_type.?).error_union.payload).optional.child);");
        }

        tab_writer.indent -= 1;

        try writer.writeAll("\n}\n");
    }
}
