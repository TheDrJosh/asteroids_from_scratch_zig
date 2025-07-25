const std = @import("std");
const builtin = @import("builtin");

const native_endian = builtin.cpu.arch.endian();

const WaylandStream = @import("WaylandStream.zig");
const WaylandObject = @import("WaylandObject.zig");

const WaylandRuntime = @This();

const wayland_types = @import("wayland_types.zig");

stream: WaylandStream,
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) !WaylandRuntime {
    return WaylandRuntime{
        .stream = try WaylandStream.init(allocator),
        .allocator = allocator,
    };
}

pub fn deinit(self: *const WaylandRuntime) void {
    self.stream.deinit();
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
    var fd_list = std.ArrayList(std.posix.fd_t).init(self.allocator);
    defer fd_list.deinit();

    inline for (comptime std.meta.fieldNames(@TypeOf(args))) |field_name| {
        const field = @field(args, field_name);

        switch (@TypeOf(@field(args, field_name))) {
            u32, i32 => {
                try message.writer().writeInt(i32, field, native_endian);
            },
            wayland_types.Fixed => {
                try message.writer().writeInt(u32, @bitCast(field), native_endian);
            },
            wayland_types.NewId => {
                try writeArray(message.writer(), field.interface, true);

                try message.writer().writeInt(u32, field.version, native_endian);
                try message.writer().writeInt(u32, field.id, native_endian);
            },
            wayland_types.String => {
                try writeArray(message.writer(), field.data, true);
            },
            []const u8, []u8 => {
                try writeArray(message.writer(), field, false);
            },
            std.ArrayList(u8) => {
                try writeArray(message.writer(), field.items, false);
            },
            wayland_types.FD => {
                try fd_list.append(field);
            },
            else => |T| {
                switch (@typeInfo(T)) {
                    .@"enum" => |e| {
                        if (e.tag_type == u32 or e.tag_type == i32) {
                            try message.writer().writeInt(u32, @bitCast(field), native_endian);
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
    const message_fd_list = try fd_list.toOwnedSlice();

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

fn readArray(reader: std.io.FixedBufferStream([]const u8).Reader, is_string: bool, allocator: std.mem.Allocator) !std.ArrayList(u8) {
    const l = try reader.readInt(u32, native_endian);

    const len = if (is_string) l - 1 else l;

    const arr = std.ArrayList(u8).init(allocator);
    try reader.readAllArrayList(&arr, len);
    std.debug.assert(len == arr.items.len);

    if (is_string) {
        try reader.readByte();
    }

    if (l % @sizeOf(u32) != 0) {
        const padding_len = @sizeOf(u32) - (l % @sizeOf(u32));
        for (0..padding_len) |_| {
            try reader.readByte();
        }
    }
}

pub fn next(self: *const WaylandRuntime, Args: type) !?Message(Args) {
    const message = try self.stream.next() orelse return null;
    defer message.deinit();

    var data_stream = std.io.fixedBufferStream(message.data);
    const data_reader = data_stream.reader();
    var fd_list_position = 0;

    var args = std.mem.zeroes(Args);

    inline for (comptime std.meta.fieldNames(Args)) |field_name| {
        const field = &@field(args, field_name);

        const T = @TypeOf(@field(args, field_name));

        switch (T) {
            u32, i32 => {
                field.* = try data_reader.readInt(T, native_endian);
            },
            wayland_types.Fixed => {
                field.* = @bitCast(try data_reader.readInt(u32, native_endian));
            },
            wayland_types.NewId => {
                field.* = wayland_types.NewId{
                    .interface = wayland_types.String{
                        .data = readArray(data_reader, true, self.allocator),
                    },
                    .allocator = self.allocator,
                    .version = try data_reader.readInt(u32, native_endian),
                    .id = try data_reader.readInt(u32, native_endian),
                };
            },
            wayland_types.String => {
                field.* = wayland_types.String{
                    .data = readArray(data_reader, true, self.allocator),
                };
            },
            std.ArrayList(u8) => {
                field.* = readArray(data_reader, false, self.allocator);
            },
            wayland_types.FD => {
                if (fd_list_position >= message.fd_list.len) {
                    return error.EndOfStream;
                }
                field.* = wayland_types.FD{
                    .fd = message.fd_list[fd_list_position],
                };
                fd_list_position += 1;
            },
            else => |E| {
                switch (@typeInfo(E)) {
                    .@"enum" => |e| {
                        if (e.tag_type == u32 or e.tag_type == i32) {
                            field.* = @bitCast(try data_reader.readInt(u32, native_endian));
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

    return .{
        .info = message.info,
        .args = args,
    };
}

pub fn Message(Args: type) type {
    return struct {
        info: WaylandStream.MessageInfo,
        args: Args,
    };
}
