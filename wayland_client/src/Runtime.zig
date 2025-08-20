const std = @import("std");
const builtin = @import("builtin");

const native_endian = builtin.cpu.arch.endian();

pub const MessageStream = @import("MessageStream.zig");

const Runtime = @This();

const types = @import("types.zig");

const Message = @import("Message.zig");

const wayland_protocol = @import("protocols").wayland;

const Display = @import("Display.zig");

fn lessThan(context: void, a: types.ObjectId, b: types.ObjectId) std.math.Order {
    _ = context;
    return std.math.order(a, b);
}

stream: MessageStream,
allocator: std.mem.Allocator,
object_register: std.ArrayList(?IObject),
object_register_mutex: std.Thread.Mutex,
reuse_ids: std.PriorityQueue(types.ObjectId, void, lessThan),
reuse_ids_mutex: std.Thread.Mutex,
next_id: types.ObjectId,

pub const IObject = struct {
    context: *anyopaque,
    vtable: *const VTable,
    pub const VTable = struct {
        handleEvent: ?*const fn (context: *anyopaque, msg: Message) void,
        handleError: ?*const fn (context: *anyopaque, code: u32, msg: []const u8) void,
    };
};

pub fn init(allocator: std.mem.Allocator) !Runtime {
    return Runtime{
        .stream = try MessageStream.init(allocator),
        .allocator = allocator,
        .object_register = .empty,
        .object_register_mutex = .{},
        .reuse_ids = .init(allocator, {}),
        .reuse_ids_mutex = .{},
        .next_id = 2,
    };
}

pub fn deinit(self: *Runtime) void {
    self.stream.deinit();
    self.reuse_ids.deinit();

    self.object_register_mutex.lock();
    defer self.object_register_mutex.unlock();
    self.object_register.deinit(self.allocator);
}

pub fn display(self: *Runtime, d: *Display) !void {
    try Display.init(d, self);
}

pub fn getId(self: *Runtime) types.ObjectId {
    self.reuse_ids_mutex.lock();
    defer self.reuse_ids_mutex.unlock();
    return self.reuse_ids.removeOrNull() orelse blk: {
        const id = self.next_id;
        self.next_id += 1;
        break :blk id;
    };
}

fn writeArray(writer: std.array_list.Managed(u8).Writer, data: []const u8, is_string: bool) !void {
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

pub fn sendRequest(self: *Runtime, object_id: u32, opcode: u16, args: anytype) !void {
    var message = std.array_list.Managed(u8).init(self.allocator);
    defer message.deinit();
    const message_writer = message.writer();
    var fd_list = std.array_list.Managed(std.posix.fd_t).init(self.allocator);
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
            std.array_list.Managed(u8) => {
                try writeArray(message_writer, field.items, false);
            },
            std.fs.File => {
                try fd_list.append(field.handle);
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
                    .pointer => {
                        try message_writer.writeInt(u32, field.object_id, native_endian);
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

    try self.stream.send(
        .{
            .info = .{
                .object = object_id,
                .opcode = opcode,
            },
            .allocator = self.allocator,
            .data = message_data,
            .fd_list = message_fd_list,
        },
    );
}

pub fn registerObject(self: *Runtime, object: anytype) !void {
    self.object_register_mutex.lock();
    defer self.object_register_mutex.unlock();

    const object_id = if (@hasField(std.meta.Child(@TypeOf(object)), "object_id")) object.object_id else std.meta.Child(@TypeOf(object)).object_id;

    if (object_id < self.object_register.items.len and self.object_register.items[object_id - 1] != null) {
        std.debug.print("object already registered type: {s}, id: {}\n", .{ std.meta.Child(@TypeOf(object)).interface, object_id });
        return error.object_already_registered;
    }

    const handleEvent: ?*const fn (context: *anyopaque, msg: Message) void = if (std.meta.hasFn(std.meta.Child(@TypeOf(object)), "handleEvent"))
        &struct {
            pub fn handleEvent(context: *anyopaque, msg: Message) void {
                const s: @TypeOf(object) = @ptrCast(@alignCast(context));
                s.handleEvent(msg);
            }
        }.handleEvent
    else
        null;

    const handleError: ?*const fn (context: *anyopaque, code: u32, msg: []const u8) void = if (std.meta.hasFn(std.meta.Child(@TypeOf(object)), "handleError"))
        &struct {
            pub fn handleError(context: *anyopaque, code: u32, msg: []const u8) void {
                const s: @TypeOf(object) = @ptrCast(@alignCast(context));
                s.handleError(code, msg);
            }
        }.handleError
    else
        null;

    // std.debug.print(
    //     "register object type: {s}, id: {}, handleEvent: {}, handleError: {}\n",
    //     .{
    //         std.meta.Child(@TypeOf(object)).interface,
    //         object_id,
    //         handleEvent != null,
    //         handleError != null,
    //     },
    // );

    if (object_id >= self.object_register.items.len) {
        try self.object_register.appendNTimes(self.allocator, null, object_id - self.object_register.items.len);
    }

    self.object_register.items[object_id - 1] = IObject{
        .context = object,
        .vtable = &.{
            .handleEvent = handleEvent,
            .handleError = handleError,
        },
    };
}

pub fn unregisterObject(self: *Runtime, object_id: types.ObjectId) void {
    self.object_register_mutex.lock();
    defer self.object_register_mutex.unlock();

    self.object_register.items[object_id - 1] = null;

    // std.debug.print("unregister object id: {}\n", .{object_id});
}

pub fn pullEvents(self: *Runtime) !void {
    while (true) {
        const msg = try self.stream.next();
        defer msg.deinit();

        self.object_register_mutex.lock();
        defer self.object_register_mutex.unlock();

        if (msg.info.object - 1 < self.object_register.items.len) {
            if (self.object_register.items[msg.info.object - 1]) |object| {
                if (object.vtable.handleEvent) |handleEvent| {
                    self.object_register_mutex.unlock();
                    handleEvent(object.context, msg);
                    self.object_register_mutex.lock();
                }
            }
        }
    }
}

test {
    @import("std").testing.refAllDecls(@This());
}
