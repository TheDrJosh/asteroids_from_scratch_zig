const std = @import("std");

const xml_parser = @import("xml_parser");

const wayland = @import("wayland.zig");
const process_protocol = @import("process_protocol.zig");
const NamespaceResolver = @import("NamespaceResolver.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var arg = try std.process.argsWithAllocator(allocator);
    defer arg.deinit();

    _ = arg.skip();

    const output_file_name = arg.next() orelse std.debug.panic("no output file provided", .{});

    const output_file = try std.fs.cwd().createFile(output_file_name, .{});
    defer output_file.close();
    var output_buf = [1]u8{0} ** 1024;
    var output_file_file_writer = output_file.writer(&output_buf);
    const output_file_writer = &output_file_file_writer.interface;
    defer output_file_writer.flush() catch unreachable;

    try output_file_writer.writeAll(
        \\const std = @import("std");
        \\const wayland_client = @import("wayland_client");
        \\
    );

    var protocols = std.ArrayList(wayland.Protocol).init(allocator);
    defer {
        for (protocols.items) |protocol| {
            protocol.deinit();
        }
        protocols.deinit();
    }

    while (arg.next()) |input_file_name| {
        const input_file = try std.fs.cwd().openFile(input_file_name, .{});
        defer input_file.close();

        // std.debug.print("file: {s}\n", .{input_file_name});

        //TODO test diffent buffer sizes
        var buffer: [8192]u8 = undefined;

        var input_file_reader = input_file.reader(&buffer);

        const xml = try xml_parser.Document.init(allocator, &input_file_reader.interface);
        defer xml.deinit();

        const protocol = try wayland.Protocol.init(allocator, xml);
        errdefer protocol.deinit();

        try protocols.append(protocol);
    }

    var resolver = NamespaceResolver.init(allocator);
    defer resolver.deinit();

    for (protocols.items) |protocol| {
        try resolver.registerProtocol(protocol);
    }

    for (protocols.items) |protocol| {
        try process_protocol.processProtocol(protocol, output_file_writer, resolver, allocator);
    }
}
