const std = @import("std");
const builtin = @import("builtin");

const native_endian = builtin.cpu.arch.endian();

const WaylandStream = @import("WaylandStream.zig");

const WaylandRuntime = @This();

const types = @import("types.zig");

const Message = @import("Message.zig");

const wayland_protocol = @import("protocols").wayland;

fn lessThan(context: void, a: types.ObjectId, b: types.ObjectId) std.math.Order {
    _ = context;
    return std.math.order(a, b);
}

stream: WaylandStream,
allocator: std.mem.Allocator,
event_buffer: std.ArrayList(Message),
reuse_ids: std.PriorityQueue(types.ObjectId, void, lessThan),
next_id: types.ObjectId,
pause_incoming: bool,

pub fn init(allocator: std.mem.Allocator) !WaylandRuntime {
    return WaylandRuntime{
        .stream = try WaylandStream.init(allocator),
        .allocator = allocator,
        .event_buffer = std.ArrayList(Message).init(allocator),
        .reuse_ids = std.PriorityQueue(types.ObjectId, void, lessThan).init(allocator, {}),
        .next_id = 2,
        .pause_incoming = false,
    };
}

pub fn deinit(self: *const WaylandRuntime) void {
    self.stream.deinit();
    self.reuse_ids.deinit();

    for (self.event_buffer.items) |msg| {
        msg.deinit();
    }
    self.event_buffer.deinit();
}

pub fn display(self: *WaylandRuntime) wayland_protocol.WlDisplay {
    return .{
        .object_id = 1,
        .runtime = self,
    };
}

pub fn getId(self: *WaylandRuntime) types.ObjectId {
    return self.reuse_ids.removeOrNull() orelse blk: {
        const id = self.next_id;
        self.next_id += 1;
        break :blk id;
    };
}

fn writeArray(writer: std.ArrayList(u8).Writer, data: []const u8, is_string: bool) !void {
    const len = if (is_string) data.len + 1 else data.len;

    try writer.writeInt(u32, @intCast(len), native_endian);

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
                try message_writer.writeInt(@TypeOf(@field(args, field_name)), field, native_endian);
            },
            types.Fixed => {
                try message_writer.writeInt(u32, @bitCast(field), native_endian);
            },
            types.NewId => {
                try writeArray(message_writer, field.interface.data(), true);

                try message_writer.writeInt(u32, field.version, native_endian);
                try message_writer.writeInt(u32, field.id, native_endian);
            },
            types.String => {
                try writeArray(message_writer, field.data(), true);
            },
            []const u8, []u8 => {
                try writeArray(message_writer, field, false);
            },
            std.ArrayList(u8) => {
                try writeArray(message_writer, field.items, false);
            },
            types.Fd => {
                try fd_list.append(field.fd);
            },
            else => |T| {
                switch (@typeInfo(T)) {
                    .@"enum" => |e| {
                        if (e.tag_type == u32 or e.tag_type == i32) {
                            try message_writer.writeInt(u32, @intFromEnum(field), native_endian);
                        } else {
                            @compileError("invalid enum arg. enum must have 32 bit tag type");
                        }
                    },
                    .@"struct" => {
                        try message_writer.writeInt(u32, field.object_id, native_endian);
                    },
                    .optional => {
                        if (field) |f| {
                            try message_writer.writeInt(u32, f.object_id, native_endian);
                        } else {
                            try message_writer.writeInt(u32, 0, native_endian);
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

fn EventsUnion(comptime events: []const type) type {
    var e_fields: []const std.builtin.Type.EnumField = &[0]std.builtin.Type.EnumField{};

    for (0..events.len) |i| {
        e_fields = e_fields ++ &[1]std.builtin.Type.EnumField{
            .{
                .name = std.fmt.comptimePrint("{}", .{i}),
                .value = i,
            },
        };
    }

    const E = @Type(std.builtin.Type{
        .@"enum" = .{
            .decls = &[0]std.builtin.Type.Declaration{},
            .is_exhaustive = true,
            .tag_type = usize,
            .fields = e_fields,
        },
    });

    var u_fields: []const std.builtin.Type.UnionField = &[0]std.builtin.Type.UnionField{};

    for (0..events.len) |i| {
        u_fields = u_fields ++ &[1]std.builtin.Type.UnionField{
            .{
                .name = std.fmt.comptimePrint("{}", .{i}),
                .type = events[i],
                .alignment = @alignOf(events[i]),
            },
        };
    }

    const U = @Type(std.builtin.Type{
        .@"union" = .{
            .decls = &[0]std.builtin.Type.Declaration{},
            .layout = .auto,
            .tag_type = E,
            .fields = u_fields,
        },
    });

    return U;
}

pub fn next(
    self: *WaylandRuntime,
    comptime events: []const type,
    object_ids: [events.len]types.ObjectId,
) !?EventsUnion(events) {
    for (0..self.event_buffer.items.len) |i| {
        inline for (0..events.len) |j| {
            if (self.event_buffer.items[i].info.object == object_ids[j] and self.event_buffer.items[i].info.opcode == events[j].opcode) {
                const msg = self.event_buffer.orderedRemove(i);
                defer msg.deinit();

                const arg = try msg.parse(events[j]);

                return @unionInit(
                    EventsUnion(events),
                    std.fmt.comptimePrint("{}", .{j}),
                    arg.args,
                );
            }
        }
    }

    if (!self.pause_incoming) {
        while (try self.stream.next()) |msg| {
            if (msg.info.object == 1) {
                defer msg.deinit();
                switch (msg.info.opcode) {
                    0 => {
                        const parsed_msg = try msg.parse(struct { object_id: types.ObjectId, code: u32, message: types.String });
                        defer parsed_msg.args.message.deinit();

                        std.debug.panic("Wayland Error recived on object({}), code({}). {s}\n", .{ parsed_msg.args.object_id, parsed_msg.args.code, parsed_msg.args.message.data() });
                    },
                    1 => {
                        const parsed_msg = try msg.parse(struct { id: u32 });

                        try self.reuse_ids.add(parsed_msg.args.id);
                    },
                    else => {},
                }
            } else {
                inline for (0..events.len) |j| {
                    if (msg.info.object == object_ids[j] and msg.info.opcode == events[j].opcode) {
                        defer msg.deinit();

                        const arg = try msg.parse(events[j]);

                        return @unionInit(
                            EventsUnion(events),
                            std.fmt.comptimePrint("{d}", .{j}),
                            arg.args,
                        );
                    }
                }

                try self.event_buffer.append(msg);
            }
        }
    }

    return null;
}
