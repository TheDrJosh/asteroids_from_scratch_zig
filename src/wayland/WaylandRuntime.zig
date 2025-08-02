const std = @import("std");
const builtin = @import("builtin");

const native_endian = builtin.cpu.arch.endian();

const WaylandStream = @import("WaylandStream.zig");

const WaylandRuntime = @This();

const wayland_types = @import("wayland_types.zig");

const Message = @import("Message.zig");

stream: WaylandStream,
allocator: std.mem.Allocator,
event_buffer: std.ArrayList(Message),
// reuse_ids: std.PriorityQueue(wayland_types.ObjectId, comptime Context: type, comptime compareFn: fn(context:Context, a:T, b:T)Order)

pub fn init(allocator: std.mem.Allocator) !WaylandRuntime {
    return WaylandRuntime{
        .stream = try WaylandStream.init(allocator),
        .allocator = allocator,
        .event_buffer = std.ArrayList(Message).init(allocator),
    };
}

pub fn deinit(self: *const WaylandRuntime) void {
    self.stream.deinit();

    for (self.event_buffer.items) |msg| {
        msg.deinit();
    }
    self.event_buffer.deinit();
}

fn writeArray(writer: std.io.FixedBufferStream([]const u8).Writer, data: []const u8, is_string: bool) !void {
    const len = if (is_string) data.len + 1 else data.len;

    try writer.writeAll(len);

    try writer.writeAll(data);

    if (is_string) {
        try writer.writeByte(0);
    }

    if (len % @sizeOf(u32) != 0) {
        const padding_len = @sizeOf(u32) - (len % @sizeOf(u32));
        try writer.writeByteNTimes(0, padding_len);
    }
}

pub fn sendRequest(self: *const WaylandRuntime, object_id: u32, opcode: u16, args: anytype) !void {
    var message = std.ArrayList(u8).init(self.allocator);
    defer message.deinit();
    const message_writer = message.writer();
    var fd_list = std.ArrayList(std.posix.fd_t).init(self.allocator);
    defer fd_list.deinit();

    inline for (comptime std.meta.fieldNames(@TypeOf(args))) |field_name| {
        const field = @field(args, field_name);

        switch (@TypeOf(@field(args, field_name))) {
            u32, i32 => {
                try message_writer.writeInt(i32, field, native_endian);
            },
            wayland_types.Fixed => {
                try message_writer.writeInt(u32, @bitCast(field), native_endian);
            },
            wayland_types.NewId => {
                try writeArray(message_writer, field.interface, true);

                try message_writer.writeInt(u32, field.version, native_endian);
                try message_writer.writeInt(u32, field.id, native_endian);
            },
            wayland_types.String => {
                try writeArray(message_writer, field.data, true);
            },
            []const u8, []u8 => {
                try writeArray(message_writer, field, false);
            },
            std.ArrayList(u8) => {
                try writeArray(message_writer, field.items, false);
            },
            wayland_types.FD => {
                try fd_list.append(field);
            },
            else => |T| {
                switch (@typeInfo(T)) {
                    .@"enum" => |e| {
                        if (e.tag_type == u32 or e.tag_type == i32) {
                            try message_writer.writeInt(u32, @bitCast(field), native_endian);
                        } else {
                            @compileError("invalid enum arg. enum must have 32 bit tag type");
                        }
                    },
                    else => {
                        @compileError("invalid arg");
                    },
                }
            },
        }
    }

    const message_data = try message.toOwnedSlice();
    defer self.allocator.free(message_data);
    const message_fd_list = try fd_list.toOwnedSlice();
    defer self.allocator.free(message_fd_list);

    try self.stream.send(.{
        .info = .{
            .object = object_id,
            .opcode = opcode,
        },
        .allocator = self.allocator,
        .data = message_data,
        .fd_list = message_fd_list,
    });
}

pub fn next(self: *WaylandRuntime, object: wayland_types.ObjectId, opcode: u16, Args: type) !?Message.TypedMessage(Args) {
    for (0..self.event_buffer.items.len) |i| {
        if (self.event_buffer.items[i].info.object == object and self.event_buffer.items[i].info.opcode == opcode) {
            const msg = self.event_buffer.orderedRemove(i);
            defer msg.deinit();
            return try msg.parse(Args);
        }
    }

    while (try self.stream.next()) |msg| {
        if (msg.info.object == 1) {
            defer msg.deinit();
            switch (msg.info.opcode) {
                0 => {
                    const parsed_msg = try msg.parse(struct { object_id: wayland_types.ObjectId, code: u32, message: wayland_types.String });
                    defer parsed_msg.args.message.data.deinit();

                    std.debug.print("Wayland Error recived on object({}), code({}). {s}\n", .{ parsed_msg.args.object_id, parsed_msg.args.code, parsed_msg.args.message.data.items });
                },
                1 => {
                    const parsed_msg = try msg.parse(struct { id: u32 });
                    _ = parsed_msg;
                    //TODO -
                },
                else => {
                    return error.unexpected_opcode_from_wl_display;
                },
            }
        } else {
            if (msg.info.object == object and msg.info.opcode == opcode) {
                defer msg.deinit();
                return try msg.parse(Args);
            } else {
                try self.event_buffer.append(msg);
            }
        }
    }

    return null;
}
