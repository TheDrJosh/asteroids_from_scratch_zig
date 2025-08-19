const std = @import("std");

const wayland = @import("wayland.zig");
const writers = @import("writers.zig");
const utils = @import("utils.zig");
const NamespaceResolver = @import("NamespaceResolver.zig");

const process_enums = @import("process_protocol/enums.zig");
const process_requests = @import("process_protocol/requests.zig");
const process_events = @import("process_protocol/events.zig");

pub fn processProtocol(protocol: wayland.Protocol, output_file_writer: *std.io.Writer, resolver: NamespaceResolver, allocator: std.mem.Allocator) !void {
    var tab_writer = writers.TabWriter.init(output_file_writer);
    const writer = &tab_writer.interface;

    try utils.writeFormatedDocComment(
        writer,
        protocol.description,
        null,
        null,
        null,
        null,
        allocator,
    );

    try writer.writeAll("pub const ");
    try writer.writeAll(protocol.name.items);
    tab_writer.indent += 1;
    try writer.writeAll(" = struct {");

    for (protocol.interfaces.items) |interface| {
        try utils.writeFormatedDocComment(
            writer,
            interface.description,
            null,
            interface.version,
            null,
            null,
            allocator,
        );

        try writer.writeAll("pub const ");
        try utils.writePascalCase(writer, interface.name.items);
        tab_writer.indent += 1;
        try writer.writeAll(" = struct {\n");

        try writer.writeAll("pub const interface = \"");
        try writer.writeAll(interface.name.items);
        try writer.print("\";\npub const version = {};\n", .{interface.version});

        try writer.writeAll("\nobject_id: wayland_client.types.ObjectId,\nruntime: *wayland_client.Runtime,\n");

        for (interface.events.items) |event| {
            try writer.print("\n{s}_event_queue: ", .{event.name.items});

            if (event.args.items.len != 0) {
                try writer.writeAll("std.ArrayList(");
                try utils.writePascalCase(writer, event.name.items);
                try writer.writeAll("Event),");
            } else {
                try writer.writeAll("u32,");
            }

            try writer.print("\n{s}_event_queue_mutex: std.Thread.Mutex,", .{event.name.items});
        }

        try writer.writeAll("\npub fn init(object: *");
        try utils.writePascalCase(writer, interface.name.items);
        try writer.writeAll(", object_id: wayland_client.types.ObjectId, runtime: *wayland_client.Runtime) !void {");
        tab_writer.indent += 1;

        try writer.writeAll("\nobject.* = .{");
        tab_writer.indent += 1;

        try writer.writeAll("\n.object_id = object_id,");
        try writer.writeAll("\n.runtime = runtime,");
        for (interface.events.items) |event| {
            try writer.print("\n.{s}_event_queue = ", .{event.name.items});
            if (event.args.items.len != 0) {
                try writer.writeAll(".empty");
            } else {
                try writer.writeAll("0");
            }
            try writer.print(",\n.{s}_event_queue_mutex = .{{}},", .{event.name.items});
        }

        tab_writer.indent -= 1;
        try writer.writeAll("\n};\ntry runtime.registerObject(object);");

        tab_writer.indent -= 1;
        try writer.writeAll("\n}");

        try writer.writeAll("\npub fn deinit(self: *");
        try utils.writePascalCase(writer, interface.name.items);
        try writer.writeAll(") void {");
        tab_writer.indent += 1;
        try writer.writeAll("\nself.runtime.unregisterObject(self.object_id);");

        for (interface.events.items) |event| {
            try writer.print("\nself.{s}_event_queue_mutex.lock();", .{event.name.items});

            var needs_element_deinit = false;

            for (event.args.items) |arg| {
                switch (arg.type) {
                    .string, .array => needs_element_deinit = true,
                    else => {},
                }
            }
            if (needs_element_deinit) {
                try writer.print("\nfor (self.{s}_event_queue.items) |e| {{", .{event.name.items});
                tab_writer.indent += 1;
                try writer.writeAll("\ne.deinit();");
                tab_writer.indent -= 1;
                try writer.writeAll("\n}");
            }

            if (event.args.items.len != 0) {
                try writer.print("\nself.{s}_event_queue.deinit(self.runtime.allocator);", .{event.name.items});
            }

            try writer.print("\nself.{s}_event_queue_mutex.unlock();", .{event.name.items});
        }

        for (interface.requests.items) |request| {
            if (request.type) |t| {
                if (std.mem.eql(u8, t.items, "destructor")) {
                    try writer.writeAll("\n_ = self.");
                    try utils.writeCammelCase(writer, request.name.items);
                    try writer.writeAll("() catch {};");
                }
            }
        }

        tab_writer.indent -= 1;
        try writer.writeAll("\n}");

        try process_enums.processEnums(&tab_writer, interface, allocator);

        try process_requests.processRequests(&tab_writer, interface, resolver, allocator);

        try process_events.processEvents(&tab_writer, interface, resolver, allocator);

        tab_writer.indent -= 1;

        try writer.writeAll("\n};");
    }

    tab_writer.indent -= 1;

    try writer.writeAll("\n};\n");
}
