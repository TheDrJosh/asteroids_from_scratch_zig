const std = @import("std");
const builtin = @import("builtin");

const wayland_types = @import("wayland_types.zig");

const native_endian = builtin.cpu.arch.endian();

const Message = @This();

info: Info,
data: []const u8,
fd_list: []const std.os.linux.fd_t,
allocator: std.mem.Allocator,

pub fn deinit(self: *const Message) void {
    self.allocator.free(self.data);
    self.allocator.free(self.fd_list);
}

pub fn parse(self: *const Message, Args: type) !TypedMessage(Args) {
    var data_stream = std.io.fixedBufferStream(self.data);
    const data_reader = data_stream.reader();
    var fd_list_position: usize = 0;

    var args: Args = undefined;

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
                        .data = try readArray(data_reader, true, self.allocator),
                    },
                    .allocator = self.allocator,
                    .version = try data_reader.readInt(u32, native_endian),
                    .id = try data_reader.readInt(u32, native_endian),
                };
            },
            wayland_types.String => {
                field.* = wayland_types.String{
                    .data = try readArray(data_reader, true, self.allocator),
                };
            },
            std.ArrayList(u8) => {
                field.* = try readArray(data_reader, false, self.allocator);
            },
            wayland_types.Fd => {
                if (fd_list_position >= self.fd_list.len) {
                    return error.EndOfStream;
                }
                field.* = wayland_types.Fd{
                    .fd = self.fd_list[fd_list_position],
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
        .info = self.info,
        .args = args,
    };
}

fn readArray(reader: std.io.FixedBufferStream([]const u8).Reader, is_string: bool, allocator: std.mem.Allocator) !std.ArrayList(u8) {
    const l = try reader.readInt(u32, native_endian);

    const len = if (is_string) l - 1 else l;

    var arr = std.ArrayList(u8).init(allocator);
    for (0..len) |_| {
        try arr.append(try reader.readByte());
    }

    if (is_string) {
        _ = try reader.readByte();
    }

    if (l % @sizeOf(u32) != 0) {
        const padding_len = @sizeOf(u32) - (l % @sizeOf(u32));
        for (0..padding_len) |_| {
            _ = try reader.readByte();
        }
    }

    return arr;
}

pub const Info = struct {
    object: wayland_types.ObjectId,
    opcode: u16,
};

pub fn TypedMessage(Args: type) type {
    return struct {
        info: Info,
        args: Args,
    };
}
