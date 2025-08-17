const std = @import("std");
const xml_parser = @import("xml_parser");

pub const Protocol = struct {
    name: std.array_list.Managed(u8),

    copyright: ?std.array_list.Managed(u8),
    description: ?Description,
    interfaces: std.array_list.Managed(Interface),

    pub fn init(allocator: std.mem.Allocator, document: *const xml_parser.Document) !Protocol {
        const protocol = document.find(null, "protocol") orelse return error.no_protocol;

        var name = std.array_list.Managed(u8).init(allocator);
        errdefer name.deinit();
        try name.appendSlice(protocol.type.entity.getAttrib("name") orelse return error.no_name);

        const copyright = try getTextFrom(protocol, "copyright", allocator);
        errdefer if (copyright) |c| c.deinit();

        const description = if (protocol.find("description")) |desc|
            try Description.init(desc, allocator)
        else
            null;
        errdefer if (description) |d| d.deinit();

        var interfaces = try processAllChildren(protocol, "interface", Interface, allocator);
        errdefer {
            for (interfaces.items) |i| {
                i.deinit();
            }
            interfaces.deinit();
        }

        return Protocol{
            .name = name,
            .copyright = copyright,
            .description = description,
            .interfaces = interfaces,
        };
    }

    pub fn deinit(self: *const Protocol) void {
        self.name.deinit();
        if (self.copyright) |str| {
            str.deinit();
        }
        if (self.description) |str| {
            str.deinit();
        }
        for (self.interfaces.items) |i| {
            i.deinit();
        }
        self.interfaces.deinit();
    }
};

pub const Interface = struct {
    name: std.array_list.Managed(u8),
    version: u32,

    description: ?Description,
    requests: std.array_list.Managed(Request),
    events: std.array_list.Managed(Event),
    enums: std.array_list.Managed(Enum),

    pub fn init(node: *const xml_parser.Node, allocator: std.mem.Allocator) !Interface {
        var name = std.array_list.Managed(u8).init(allocator);
        errdefer name.deinit();
        try name.appendSlice(node.type.entity.getAttrib("name") orelse return error.no_name);

        const version = if (node.type.entity.getAttrib("version")) |str| try std.fmt.parseInt(u32, str, 0) else return error.no_version;

        const description = if (node.find("description")) |desc|
            try Description.init(desc, allocator)
        else
            null;
        errdefer if (description) |d| d.deinit();

        var requests = try processAllChildren(node, "request", Request, allocator);
        errdefer {
            for (requests.items) |i| {
                i.deinit();
            }
            requests.deinit();
        }

        var events = try processAllChildren(node, "event", Event, allocator);
        errdefer {
            for (events.items) |i| {
                i.deinit();
            }
            events.deinit();
        }

        var enums = try processAllChildren(node, "enum", Enum, allocator);
        errdefer {
            for (enums.items) |i| {
                i.deinit();
            }
            enums.deinit();
        }

        return Interface{
            .name = name,
            .version = version,
            .description = description,
            .requests = requests,
            .events = events,
            .enums = enums,
        };
    }

    pub fn deinit(self: *const Interface) void {
        self.name.deinit();

        if (self.description) |str| {
            str.deinit();
        }

        for (self.requests.items) |i| {
            i.deinit();
        }
        self.requests.deinit();

        for (self.events.items) |i| {
            i.deinit();
        }
        self.events.deinit();

        for (self.enums.items) |i| {
            i.deinit();
        }
        self.enums.deinit();
    }
};

pub const Request = struct {
    name: std.array_list.Managed(u8),
    type: ?std.array_list.Managed(u8),
    since: ?u32,
    deprecated_since: ?u32,

    description: ?Description,
    args: std.array_list.Managed(Arg),

    pub fn init(node: *const xml_parser.Node, allocator: std.mem.Allocator) !Request {
        var name = std.array_list.Managed(u8).init(allocator);
        errdefer name.deinit();
        try name.appendSlice(node.type.entity.getAttrib("name") orelse return error.no_name);

        const _type = if (node.type.entity.getAttrib("type")) |str| blk: {
            var string = std.array_list.Managed(u8).init(allocator);
            errdefer string.deinit();
            try string.appendSlice(str);
            break :blk string;
        } else null;
        errdefer if (_type) |s| s.deinit();

        const since = if (node.type.entity.getAttrib("since")) |str| try std.fmt.parseInt(u32, str, 0) else null;

        const deprecated_since = if (node.type.entity.getAttrib("deprecated-since")) |str| try std.fmt.parseInt(u32, str, 0) else null;

        const description = if (node.find("description")) |desc|
            try Description.init(desc, allocator)
        else
            null;
        errdefer if (description) |d| d.deinit();

        var args = try processAllChildren(node, "arg", Arg, allocator);
        errdefer {
            for (args.items) |i| {
                i.deinit();
            }
            args.deinit();
        }

        return Request{
            .name = name,
            .type = _type,
            .since = since,
            .deprecated_since = deprecated_since,
            .description = description,
            .args = args,
        };
    }

    pub fn deinit(self: *const Request) void {
        self.name.deinit();
        if (self.description) |str| {
            str.deinit();
        }
        if (self.type) |str| {
            str.deinit();
        }

        for (self.args.items) |i| {
            i.deinit();
        }
        self.args.deinit();
    }
};

pub const Event = struct {
    name: std.array_list.Managed(u8),
    type: ?std.array_list.Managed(u8),
    since: ?u32,
    deprecated_since: ?u32,

    description: ?Description,
    args: std.array_list.Managed(Arg),

    pub fn init(node: *const xml_parser.Node, allocator: std.mem.Allocator) !Event {
        var name = std.array_list.Managed(u8).init(allocator);
        errdefer name.deinit();
        try name.appendSlice(node.type.entity.getAttrib("name") orelse return error.no_name);

        const _type = if (node.type.entity.getAttrib("type")) |str| blk: {
            var string = std.array_list.Managed(u8).init(allocator);
            errdefer string.deinit();
            try string.appendSlice(str);
            break :blk string;
        } else null;
        errdefer if (_type) |s| s.deinit();

        const since = if (node.type.entity.getAttrib("since")) |str| try std.fmt.parseInt(u32, str, 0) else null;

        const deprecated_since = if (node.type.entity.getAttrib("deprecated-since")) |str| try std.fmt.parseInt(u32, str, 0) else null;

        const description = if (node.find("description")) |desc|
            try Description.init(desc, allocator)
        else
            null;
        errdefer if (description) |d| d.deinit();

        var args = try processAllChildren(node, "arg", Arg, allocator);
        errdefer {
            for (args.items) |i| {
                i.deinit();
            }
            args.deinit();
        }

        return Event{
            .name = name,
            .type = _type,
            .since = since,
            .deprecated_since = deprecated_since,
            .description = description,
            .args = args,
        };
    }

    pub fn deinit(self: *const Event) void {
        self.name.deinit();
        if (self.description) |str| {
            str.deinit();
        }
        if (self.type) |str| {
            str.deinit();
        }

        for (self.args.items) |i| {
            i.deinit();
        }
        self.args.deinit();
    }
};

pub const Enum = struct {
    name: std.array_list.Managed(u8),
    since: ?u32,
    bitfield: bool,

    description: ?Description,
    entries: std.array_list.Managed(Entry),

    pub fn init(node: *const xml_parser.Node, allocator: std.mem.Allocator) !Enum {
        var name = std.array_list.Managed(u8).init(allocator);
        errdefer name.deinit();
        try name.appendSlice(node.type.entity.getAttrib("name") orelse return error.no_name);

        const since = if (node.type.entity.getAttrib("since")) |str| try std.fmt.parseInt(u32, str, 0) else null;

        const bitfield = if (node.type.entity.getAttrib("bitfield")) |str| std.mem.eql(u8, str, "true") else false;

        const description = if (node.find("description")) |desc|
            try Description.init(desc, allocator)
        else
            null;
        errdefer if (description) |d| d.deinit();

        var entries = try processAllChildren(node, "entry", Entry, allocator);
        errdefer {
            for (entries.items) |i| {
                i.deinit();
            }
            entries.deinit();
        }

        return Enum{
            .name = name,
            .since = since,
            .bitfield = bitfield,
            .description = description,
            .entries = entries,
        };
    }

    pub fn deinit(self: *const Enum) void {
        self.name.deinit();
        if (self.description) |str| {
            str.deinit();
        }

        for (self.entries.items) |i| {
            i.deinit();
        }
        self.entries.deinit();
    }
};

pub const Entry = struct {
    name: std.array_list.Managed(u8),
    value: u32,
    summary: ?std.array_list.Managed(u8),
    since: ?u32,
    deprecated_since: ?u32,

    description: ?Description,

    pub fn init(node: *const xml_parser.Node, allocator: std.mem.Allocator) !Entry {
        var name = std.array_list.Managed(u8).init(allocator);
        errdefer name.deinit();
        try name.appendSlice(node.type.entity.getAttrib("name") orelse return error.no_name);

        const value = if (node.type.entity.getAttrib("value")) |str| blk: {
            const n = try std.fmt.parseInt(i64, str, 0);
            if (n >= 0) {
                break :blk @as(u32, @intCast(n));
            } else {
                break :blk @as(u32, @bitCast(@as(i32, @intCast(n))));
            }
        } else return error.no_value;

        const summary = if (node.type.entity.getAttrib("summary")) |str| blk: {
            var string = std.array_list.Managed(u8).init(allocator);
            errdefer string.deinit();
            try string.appendSlice(str);
            break :blk string;
        } else null;
        errdefer if (summary) |s| s.deinit();

        const since = if (node.type.entity.getAttrib("since")) |str| try std.fmt.parseInt(u32, str, 0) else null;

        const deprecated_since = if (node.type.entity.getAttrib("deprecated-since")) |str| try std.fmt.parseInt(u32, str, 0) else null;

        const description = if (node.find("description")) |desc|
            try Description.init(desc, allocator)
        else
            null;
        errdefer if (description) |d| d.deinit();

        return Entry{
            .name = name,
            .value = value,
            .summary = summary,
            .since = since,
            .deprecated_since = deprecated_since,
            .description = description,
        };
    }

    pub fn deinit(self: *const Entry) void {
        self.name.deinit();
        if (self.summary) |str| {
            str.deinit();
        }
        if (self.description) |str| {
            str.deinit();
        }
    }
};

pub const Arg = struct {
    name: std.array_list.Managed(u8),
    type: Type,
    summary: ?std.array_list.Managed(u8),
    interface: ?std.array_list.Managed(u8),
    allow_null: bool,
    @"enum": ?std.array_list.Managed(u8),

    description: ?Description,

    pub fn init(node: *const xml_parser.Node, allocator: std.mem.Allocator) !Arg {
        var name = std.array_list.Managed(u8).init(allocator);
        errdefer name.deinit();
        try name.appendSlice(node.type.entity.getAttrib("name") orelse return error.no_name);

        const @"type" = try Type.parse(node.type.entity.getAttrib("type") orelse return error.no_value);

        const summary = if (node.type.entity.getAttrib("summary")) |str| blk: {
            var string = std.array_list.Managed(u8).init(allocator);
            errdefer string.deinit();
            try string.appendSlice(str);
            break :blk string;
        } else null;
        errdefer if (summary) |s| s.deinit();

        const interface = if (node.type.entity.getAttrib("interface")) |str| blk: {
            var string = std.array_list.Managed(u8).init(allocator);
            errdefer string.deinit();
            try string.appendSlice(str);
            break :blk string;
        } else null;
        errdefer if (interface) |s| s.deinit();

        const allow_null = if (node.type.entity.getAttrib("allow-null")) |str| std.mem.eql(u8, str, "true") else false;

        const @"enum" = if (node.type.entity.getAttrib("enum")) |str| blk: {
            var string = std.array_list.Managed(u8).init(allocator);
            errdefer string.deinit();
            try string.appendSlice(str);
            break :blk string;
        } else null;
        errdefer if (@"enum") |s| s.deinit();

        const description = if (node.find("description")) |desc|
            try Description.init(desc, allocator)
        else
            null;
        errdefer if (description) |d| d.deinit();

        return Arg{
            .name = name,
            .type = @"type",
            .summary = summary,
            .interface = interface,
            .allow_null = allow_null,
            .@"enum" = @"enum",
            .description = description,
        };
    }

    pub fn deinit(self: *const Arg) void {
        self.name.deinit();
        if (self.summary) |str| {
            str.deinit();
        }
        if (self.interface) |str| {
            str.deinit();
        }

        if (self.@"enum") |str| {
            str.deinit();
        }
        if (self.description) |str| {
            str.deinit();
        }
    }
};

pub const Description = struct {
    summary: std.array_list.Managed(u8),
    description: std.array_list.Managed(u8),

    pub fn init(node: *const xml_parser.Node, allocator: std.mem.Allocator) !Description {
        var summary = std.array_list.Managed(u8).init(allocator);
        errdefer summary.deinit();
        try summary.appendSlice(node.type.entity.getAttrib("summary") orelse return error.no_summary);

        var description = std.array_list.Managed(u8).init(allocator);
        errdefer description.deinit();

        try description.appendSlice(try node.getText() orelse "");

        return Description{
            .summary = summary,
            .description = description,
        };
    }

    pub fn deinit(self: *const Description) void {
        self.summary.deinit();
        self.description.deinit();
    }
};

fn getTextFrom(node: *const xml_parser.Node, name: []const u8, allocator: std.mem.Allocator) !?std.array_list.Managed(u8) {
    var s = std.array_list.Managed(u8).init(allocator);

    if (try (node.find(name) orelse return null).getText()) |str| {
        try s.appendSlice(str);
    }
    return s;
}

fn processAllChildren(node: *const xml_parser.Node, name: []const u8, comptime T: type, allocator: std.mem.Allocator) !std.array_list.Managed(T) {
    var ts = std.array_list.Managed(T).init(allocator);
    errdefer {
        for (ts.items) |i| {
            i.deinit();
        }
        ts.deinit();
    }

    var iter = node.findAll(name);

    while (iter.next()) |t| {
        try ts.append(try T.init(t, allocator));
    }

    return ts;
}

pub const Type = enum {
    int,
    uint,
    fixed,
    string,
    object,
    new_id,
    array,
    fd,

    pub fn parse(str: []const u8) !Type {
        inline for (std.meta.fieldNames(Type)) |name| {
            if (std.mem.eql(u8, str, name)) {
                return std.meta.stringToEnum(Type, name) orelse undefined;
            }
        }
        return error.type_parse;
    }
};
