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

        try writer.writeAll("\nobject_id: types.ObjectId,\nruntime: *WaylandRuntime,\n");

        try process_enums.processEnums(&tab_writer, interface, allocator);

        try process_requests.processRequests(&tab_writer, interface, resolver, allocator);

        try process_events.processEvents(&tab_writer, interface, resolver, allocator);

        tab_writer.indent -= 1;

        try writer.writeAll("\n};");
    }

    tab_writer.indent -= 1;

    try writer.writeAll("\n};\n");
}
