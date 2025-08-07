const std = @import("std");

const xml_parser = @import("xml_parser");

const wayland = @import("wayland.zig");
const process_protocol = @import("process_protocol.zig");

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
    const output_file_writer = output_file.writer();

    try output_file_writer.writeAll(
        \\const std = @import("std");
        \\const wayland_client = @import("wayland_client");
        \\const WaylandRuntime = wayland_client.WaylandRuntime;
        \\const types = wayland_client.types;
        \\
    );

    while (arg.next()) |input_file_name| {
        const input_file = try std.fs.cwd().openFile(input_file_name, .{});
        defer input_file.close();

        const input_file_contents = try input_file.readToEndAlloc(allocator, std.math.maxInt(usize));
        defer allocator.free(input_file_contents);

        const xml = try xml_parser.Document.init(input_file_contents, allocator);
        defer xml.deinit();

        const protocol = try wayland.Protocol.init(xml.root, allocator);
        defer protocol.deinit();

        try process_protocol.processProtocol(protocol, output_file_writer, allocator);
    }
}
