const std = @import("std");
const wayland = @import("../wayland.zig");
const TabWriter = @import("../writers.zig").TabWriter;
const utils = @import("../utils.zig");
const NamespaceResolver = @import("../NamespaceResolver.zig");

pub fn processEvents(tab_writer: *TabWriter, interface: wayland.Interface, resolver: NamespaceResolver, allocator: std.mem.Allocator) !void {
    const writer = &tab_writer.interface;

    var has_event = false;

    for (interface.events.items) |event| {
        has_event = true;
        try utils.writeFormatedDocComment(
            writer,
            event.description,
            null,
            null,
            event.since,
            event.deprecated_since,
            allocator,
        );

        if (event.args.items.len != 0) {
            try writer.writeAll("pub const ");
            try utils.writePascalCase(writer, event.name.items);
            try writer.writeAll("Event = ");

            tab_writer.indent += 1;
            try writer.writeAll("struct {");

            var need_deinit = false;

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
                        need_deinit = true;
                        try writer.writeAll("wayland_client.types.String");
                    },
                    .object => {
                        if (arg.allow_null) {
                            try writer.writeAll("?");
                        }

                        if (arg.interface) |inter| {
                            try writer.writeAll("*");
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
                        need_deinit = true;

                        try writer.writeAll("std.array_list.Managed(u8)");
                    },
                    .fd => {
                        try writer.writeAll("std.fs.File");
                    },
                }
                try writer.writeAll(",");
            }

            if (need_deinit) {
                try writer.writeAll("\npub fn deinit(self: *const ");
                try utils.writePascalCase(writer, event.name.items);
                try writer.writeAll("Event) void {");
                tab_writer.indent += 1;

                for (event.args.items) |arg| {
                    switch (arg.type) {
                        .int => {},
                        .uint => {},
                        .fixed => {},
                        .string => {
                            try writer.print("self.{s}.deinit();", .{arg.name.items});
                        },
                        .object => {
                            try writer.print("self.{s}.deinit();", .{arg.name.items});
                        },
                        .new_id => {
                            // ?
                        },
                        .array => {
                            try writer.print("self.{s}.deinit();", .{arg.name.items});
                        },
                        .fd => {},
                    }
                }
                tab_writer.indent -= 1;
                try writer.writeAll("\n}");
            }

            tab_writer.indent -= 1;
            try writer.writeAll("\n};");
        }

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

        try writer.writeAll("(self: *");

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

        try writer.print(" {{\nself.{s}_event_queue_mutex.lock();", .{event.name.items});
        try writer.print("\ndefer self.{s}_event_queue_mutex.unlock();", .{event.name.items});

        if (event.args.items.len != 0) {
            try writer.print("\nreturn self.{s}_event_queue.pop();", .{event.name.items});
        } else {
            try writer.print("\nif (self.{s}_event_queue > 0) {{", .{event.name.items});
            tab_writer.indent += 1;
            try writer.print("\nself.{s}_event_queue -= 1;\nreturn true;", .{event.name.items});
            tab_writer.indent -= 1;
            try writer.writeAll("\n} else {");
            tab_writer.indent += 1;
            try writer.writeAll("\nreturn false;");
            tab_writer.indent -= 1;
            try writer.writeAll("\n}");
        }

        tab_writer.indent -= 1;

        try writer.writeAll("\n}");
    }

    if (has_event) {
        try writer.writeAll("\npub fn handleEvent(self: *");
        try utils.writePascalCase(writer, interface.name.items);
        try writer.writeAll(", msg: wayland_client.Runtime.MessageStream.Message) void {");
        tab_writer.indent += 1;

        try writer.writeAll("\nswitch (msg.info.opcode) {");
        tab_writer.indent += 1;

        for (interface.events.items, 0..) |event, opcode| {
            try writer.print("\n{d} => {{", .{opcode});
            tab_writer.indent += 1;

            try writer.print("\nself.{s}_event_queue_mutex.lock();", .{event.name.items});
            try writer.print("\ndefer self.{s}_event_queue_mutex.unlock();", .{event.name.items});
            if (event.args.items.len != 0) {
                try writer.print("\nself.{s}_event_queue.append(self.runtime.allocator, (msg.parse(", .{event.name.items});
                try utils.writePascalCase(writer, event.name.items);

                try writer.writeAll("Event, self.runtime) catch @panic(\"failed to parse event args\")).args) catch unreachable;");
            } else {
                try writer.print("\nself.{s}_event_queue += 1;", .{event.name.items});
            }

            tab_writer.indent -= 1;
            try writer.writeAll("\n},");
        }

        try writer.writeAll("\nelse => {},");

        tab_writer.indent -= 1;
        try writer.writeAll("\n}");

        tab_writer.indent -= 1;
        try writer.writeAll("\n}");
    }
}
