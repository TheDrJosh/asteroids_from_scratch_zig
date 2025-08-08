const std = @import("std");
const wayland = @import("../wayland.zig");
const TabWriter = @import("../writers.zig").TabWriter;
const utils = @import("../utils.zig");
const NamespaceResolver = @import("../NamespaceResolver.zig");

pub fn processRequests(tab_writer: *TabWriter, interface: wayland.Interface, resolver: NamespaceResolver, allocator: std.mem.Allocator) !void {
    const writer = &tab_writer.interface;

    for (interface.requests.items, 0..) |request, opcode| {
        try utils.writeFormatedDocComment(
            writer,
            request.description,
            null,
            null,
            request.since,
            request.deprecated_since,
            allocator,
        );

        try writer.writeAll("pub fn ");

        try utils.writeCammelCase(writer, request.name.items);

        try writer.writeAll("(");

        tab_writer.indent += 1;

        try writer.writeAll("\nself: *const ");

        try utils.writePascalCase(writer, interface.name.items);

        try writer.writeAll(",");

        var new_ids = std.ArrayList(wayland.Arg).init(allocator);
        defer new_ids.deinit();

        for (request.args.items) |arg| {
            if (arg.type == .new_id) {
                try new_ids.append(arg);
            }

            if (arg.type == .new_id and arg.interface != null) {
                continue;
            }

            try utils.writeFormatedDocComment(writer, arg.description, arg.summary, null, null, null, allocator);

            if (arg.type != .new_id) {
                try writer.writeAll(arg.name.items);
            } else {
                try utils.writePascalCase(writer, arg.name.items);
            }
            try writer.writeAll(": ");

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
                    try writer.writeAll("[]const u8");
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
                    try writer.writeAll("type,\n");
                    try writer.writeAll(arg.name.items);
                    try writer.writeAll("_version: ?u32");
                },
                .array => {
                    try writer.writeAll("[]const u8");
                },
                .fd => {
                    try writer.writeAll("std.posix.fd_t");
                },
            }
            try writer.writeAll(",");
        }

        tab_writer.indent -= 1;

        try writer.writeAll("\n) !");

        switch (new_ids.items.len) {
            0 => {
                try writer.writeAll("void");
            },
            1 => {
                if (new_ids.items[0].interface) |inter| {
                    try utils.writePascalCase(writer, inter.items);
                } else {
                    try utils.writePascalCase(writer, new_ids.items[0].name.items);
                }
            },
            else => {
                try writer.writeAll("struct {");
                tab_writer.indent += 1;

                for (new_ids.items) |new_id| {
                    try utils.writeFormatedDocComment(
                        writer,
                        new_id.description,
                        new_id.summary,
                        null,
                        null,
                        null,
                        allocator,
                    );
                    try writer.writeAll(new_id.name.items);
                    try writer.writeAll(": ");
                    if (new_id.interface) |inter| {
                        try resolver.writeResolvedInterface(writer, inter.items);
                    } else {
                        try utils.writePascalCase(writer, new_id.name.items);
                    }
                }

                tab_writer.indent -= 1;

                try writer.writeAll("\n}");
            },
        }

        tab_writer.indent += 1;

        try writer.writeAll(" {\n");

        for (new_ids.items) |new_id| {
            try writer.print("const {s}_id = self.runtime.getId();\n", .{new_id.name.items});
        }

        try writer.print("try self.runtime.sendRequest(self.object_id, {}, .{{", .{opcode});
        tab_writer.indent += 1;

        for (request.args.items) |arg| {
            switch (arg.type) {
                .string => {
                    try writer.print("\ntypes.String{{ .static = {s} }},", .{arg.name.items});
                },
                .new_id => {
                    if (arg.interface) |_| {
                        try writer.print("\n{s}_id,", .{arg.name.items});
                    } else {
                        try writer.print("\ntypes.NewId{{ .id = {s}_id, .interface = .{{ .static = ", .{arg.name.items});

                        try utils.writePascalCase(writer, arg.name.items);

                        try writer.print(".interface }}, .version = {s}_version orelse ", .{arg.name.items});

                        try utils.writePascalCase(writer, arg.name.items);

                        try writer.writeAll(".version },");
                    }
                },
                .fd => {
                    try writer.print("\ntypes.Fd{{ .fd = {s} }},", .{arg.name.items});
                },
                else => {
                    try writer.print("\n{s},", .{arg.name.items});
                },
            }
        }

        tab_writer.indent -= 1;

        if (request.args.items.len > 0) {
            try writer.writeAll("\n");
        }

        try writer.writeAll("});");

        switch (new_ids.items.len) {
            0 => {},
            1 => {
                try writer.writeAll("\n\nreturn ");

                if (new_ids.items[0].interface) |inter| {
                    try utils.writePascalCase(writer, inter.items);
                } else {
                    try utils.writePascalCase(writer, new_ids.items[0].name.items);
                }
                try writer.print("{{ .object_id = {s}_id, .runtime = self.runtime }};", .{new_ids.items[0].name.items});
            },
            else => {
                try writer.writeAll("\n\nreturn .{");
                tab_writer.indent += 1;

                for (new_ids.items) |new_id| {
                    try writer.print(".{s} = ", .{new_ids.items[0].name.items});
                    if (new_id.interface) |inter| {
                        try utils.writePascalCase(writer, inter.items);
                    } else {
                        try utils.writePascalCase(writer, new_id.name.items);
                    }
                    try writer.print("{{ .object_id = {s}_id, .runtime = self.runtime }},", .{new_ids.items[0].name.items});
                }

                tab_writer.indent -= 1;
                try writer.writeAll("\n};");
            },
        }

        tab_writer.indent -= 1;

        try writer.writeAll("\n}");
    }

    //TODO use request types
}
