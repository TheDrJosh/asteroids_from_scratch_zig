const std = @import("std");
const xml_praser = @import("xml_parser");

pub const Protocol = struct {
    name: std.ArrayList(u8),

    copyright: ?std.ArrayList(u8),
    description: ?Description,
    interfaces: std.ArrayList(Interface),

    pub fn init(node: *xml_praser.Document.Node, allocator: std.mem.Allocator) !Protocol {
        var name = std.ArrayList(u8).init(allocator);
        errdefer name.deinit();
        try name.appendSlice(node.getAttrib("name") orelse return error.no_name);

        const copyright = try getTextFrom(node, "copyright", allocator);
        errdefer if (copyright) |c| c.deinit();

        const description = if (node.find("description")) |desc| try Description.init(desc, allocator) else null;
        errdefer if (description) |d| d.deinit();

        var interfaces = try processAllChildren(node, "interface", Interface, allocator);
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
    name: std.ArrayList(u8),
    version: std.ArrayList(u8),

    description: ?Description,
    requests: std.ArrayList(Request),
    events: std.ArrayList(Event),
    enums: std.ArrayList(Enum),

    pub fn init(node: *xml_praser.Document.Node, allocator: std.mem.Allocator) !Interface {
        var name = std.ArrayList(u8).init(allocator);
        errdefer name.deinit();
        try name.appendSlice(node.getAttrib("name") orelse return error.no_name);

        var version = std.ArrayList(u8).init(allocator);
        errdefer version.deinit();
        try version.appendSlice(node.getAttrib("version") orelse return error.no_version);

        const description = if (node.find("description")) |desc| try Description.init(desc, allocator) else null;
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
        self.version.deinit();

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
    name: std.ArrayList(u8),
    type: ?std.ArrayList(u8),
    since: ?std.ArrayList(u8),
    deprecated_since: ?std.ArrayList(u8),

    description: ?Description,
    args: std.ArrayList(Arg),

    pub fn init(node: *xml_praser.Document.Node, allocator: std.mem.Allocator) !Request {
        var name = std.ArrayList(u8).init(allocator);
        errdefer name.deinit();
        try name.appendSlice(node.getAttrib("name") orelse return error.no_name);

        const _type = if (node.getAttrib("type")) |str| blk: {
            var string = std.ArrayList(u8).init(allocator);
            errdefer string.deinit();
            try string.appendSlice(str);
            break :blk string;
        } else null;
        errdefer if (_type) |s| s.deinit();

        const since = if (node.getAttrib("since")) |str| blk: {
            var string = std.ArrayList(u8).init(allocator);
            errdefer string.deinit();
            try string.appendSlice(str);
            break :blk string;
        } else null;
        errdefer if (since) |s| s.deinit();

        const deprecated_since = if (node.getAttrib("deprecated_since")) |str| blk: {
            var string = std.ArrayList(u8).init(allocator);
            errdefer string.deinit();
            try string.appendSlice(str);
            break :blk string;
        } else null;
        errdefer if (deprecated_since) |s| s.deinit();

        const description = if (node.find("description")) |desc| try Description.init(desc, allocator) else null;
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
        if (self.since) |str| {
            str.deinit();
        }

        if (self.deprecated_since) |str| {
            str.deinit();
        }

        for (self.args.items) |i| {
            i.deinit();
        }
        self.args.deinit();
    }
};

pub const Event = struct {
    name: std.ArrayList(u8),
    type: ?std.ArrayList(u8),
    since: ?std.ArrayList(u8),
    deprecated_since: ?std.ArrayList(u8),

    description: ?Description,
    args: std.ArrayList(Arg),

    pub fn init(node: *xml_praser.Document.Node, allocator: std.mem.Allocator) !Event {
        var name = std.ArrayList(u8).init(allocator);
        errdefer name.deinit();
        try name.appendSlice(node.getAttrib("name") orelse return error.no_name);

        const _type = if (node.getAttrib("type")) |str| blk: {
            var string = std.ArrayList(u8).init(allocator);
            errdefer string.deinit();
            try string.appendSlice(str);
            break :blk string;
        } else null;
        errdefer if (_type) |s| s.deinit();

        const since = if (node.getAttrib("since")) |str| blk: {
            var string = std.ArrayList(u8).init(allocator);
            errdefer string.deinit();
            try string.appendSlice(str);
            break :blk string;
        } else null;
        errdefer if (since) |s| s.deinit();

        const deprecated_since = if (node.getAttrib("deprecated_since")) |str| blk: {
            var string = std.ArrayList(u8).init(allocator);
            errdefer string.deinit();
            try string.appendSlice(str);
            break :blk string;
        } else null;
        errdefer if (deprecated_since) |s| s.deinit();

        const description = if (node.find("description")) |desc| try Description.init(desc, allocator) else null;
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
        if (self.since) |str| {
            str.deinit();
        }

        if (self.deprecated_since) |str| {
            str.deinit();
        }

        for (self.args.items) |i| {
            i.deinit();
        }
        self.args.deinit();
    }
};

pub const Enum = struct {
    name: std.ArrayList(u8),
    since: ?std.ArrayList(u8),
    bitfield: bool,

    description: ?Description,
    entries: std.ArrayList(Entry),

    pub fn init(node: *xml_praser.Document.Node, allocator: std.mem.Allocator) !Enum {
        var name = std.ArrayList(u8).init(allocator);
        errdefer name.deinit();
        try name.appendSlice(node.getAttrib("name") orelse return error.no_name);

        const since = if (node.getAttrib("since")) |str| blk: {
            var string = std.ArrayList(u8).init(allocator);
            errdefer string.deinit();
            try string.appendSlice(str);
            break :blk string;
        } else null;
        errdefer if (since) |s| s.deinit();

        const bitfield_str = if (node.getAttrib("bitfield")) |str| blk: {
            var string = std.ArrayList(u8).init(allocator);
            errdefer string.deinit();
            try string.appendSlice(str);
            break :blk string;
        } else null;
        defer if (bitfield_str) |s| s.deinit();

        const bitfield = if (bitfield_str) |str| std.mem.eql(u8, str, "true") else false;

        const description = if (node.find("description")) |desc| try Description.init(desc, allocator) else null;
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
        if (self.since) |str| {
            str.deinit();
        }
        if (self.bitfield) |str| {
            str.deinit();
        }

        for (self.entries.items) |i| {
            i.deinit();
        }
        self.entries.deinit();
    }
};

pub const Entry = struct {
    name: std.ArrayList(u8),
    value: std.ArrayList(u8),
    summary: ?std.ArrayList(u8),
    since: ?std.ArrayList(u8),
    deprecated_since: ?std.ArrayList(u8),

    description: ?Description,

    pub fn init(node: *xml_praser.Document.Node, allocator: std.mem.Allocator) !Entry {
        var name = std.ArrayList(u8).init(allocator);
        errdefer name.deinit();
        try name.appendSlice(node.getAttrib("name") orelse return error.no_name);

        var value = std.ArrayList(u8).init(allocator);
        errdefer value.deinit();
        try value.appendSlice(node.getAttrib("value") orelse return error.no_value);

        const summary = if (node.getAttrib("summary")) |str| blk: {
            var string = std.ArrayList(u8).init(allocator);
            errdefer string.deinit();
            try string.appendSlice(str);
            break :blk string;
        } else null;
        errdefer if (summary) |s| s.deinit();

        const since = if (node.getAttrib("since")) |str| blk: {
            var string = std.ArrayList(u8).init(allocator);
            errdefer string.deinit();
            try string.appendSlice(str);
            break :blk string;
        } else null;
        errdefer if (since) |s| s.deinit();

        const deprecated_since = if (node.getAttrib("deprecated_since")) |str| blk: {
            var string = std.ArrayList(u8).init(allocator);
            errdefer string.deinit();
            try string.appendSlice(str);
            break :blk string;
        } else null;
        errdefer if (deprecated_since) |s| s.deinit();

        const description = if (node.find("description")) |desc| try Description.init(desc, allocator) else null;
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
        self.value.deinit();
        if (self.summary) |str| {
            str.deinit();
        }
        if (self.since) |str| {
            str.deinit();
        }
        if (self.deprecated_since) |str| {
            str.deinit();
        }

        if (self.description) |str| {
            str.deinit();
        }
    }
};

pub const Arg = struct {
    name: std.ArrayList(u8),
    type: std.ArrayList(u8),
    summary: ?std.ArrayList(u8),
    interface: ?std.ArrayList(u8),
    allow_null: ?std.ArrayList(u8),
    @"enum": ?std.ArrayList(u8),

    description: ?Description,

    pub fn init(node: *xml_praser.Document.Node, allocator: std.mem.Allocator) !Arg {
        var name = std.ArrayList(u8).init(allocator);
        errdefer name.deinit();
        try name.appendSlice(node.getAttrib("name") orelse return error.no_name);

        var @"type" = std.ArrayList(u8).init(allocator);
        errdefer @"type".deinit();
        try @"type".appendSlice(node.getAttrib("type") orelse return error.no_value);

        const summary = if (node.getAttrib("summary")) |str| blk: {
            var string = std.ArrayList(u8).init(allocator);
            errdefer string.deinit();
            try string.appendSlice(str);
            break :blk string;
        } else null;
        errdefer if (summary) |s| s.deinit();

        const interface = if (node.getAttrib("interface")) |str| blk: {
            var string = std.ArrayList(u8).init(allocator);
            errdefer string.deinit();
            try string.appendSlice(str);
            break :blk string;
        } else null;
        errdefer if (interface) |s| s.deinit();

        const allow_null = if (node.getAttrib("allow_null")) |str| blk: {
            var string = std.ArrayList(u8).init(allocator);
            errdefer string.deinit();
            try string.appendSlice(str);
            break :blk string;
        } else null;
        errdefer if (allow_null) |s| s.deinit();

        const @"enum" = if (node.getAttrib("enum")) |str| blk: {
            var string = std.ArrayList(u8).init(allocator);
            errdefer string.deinit();
            try string.appendSlice(str);
            break :blk string;
        } else null;
        errdefer if (@"enum") |s| s.deinit();

        const description = if (node.find("description")) |desc| try Description.init(desc, allocator) else null;
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
        self.type.deinit();
        if (self.summary) |str| {
            str.deinit();
        }
        if (self.interface) |str| {
            str.deinit();
        }
        if (self.allow_null) |str| {
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

const Description = struct {
    summary: std.ArrayList(u8),
    description: std.ArrayList(u8),

    pub fn init(node: *xml_praser.Document.Node, allocator: std.mem.Allocator) !Description {
        var summary = std.ArrayList(u8).init(allocator);
        errdefer summary.deinit();
        try summary.appendSlice(node.getAttrib("summary") orelse return error.no_summary);

        var description = std.ArrayList(u8).init(allocator);
        errdefer description.deinit();

        var iter = node.text();
        while (iter.next()) |str| {
            try description.appendSlice(str);
        }

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

fn getTextFrom(node: *xml_praser.Document.Node, name: []const u8, allocator: std.mem.Allocator) !?std.ArrayList(u8) {
    if (node.find(name)) |n| {
        var iter = n.text();
        if (iter.next()) |str| {
            var s = std.ArrayList(u8).init(allocator);
            errdefer s.deinit();
            try s.appendSlice(str);
            return s;
        }
    }
    return null;
}

fn processAllChildren(node: *xml_praser.Document.Node, name: []const u8, comptime T: type, allocator: std.mem.Allocator) !std.ArrayList(T) {
    var ts = std.ArrayList(T).init(allocator);
    errdefer {
        for (ts.items) |i| {
            i.deinit();
        }
        ts.deinit();
    }

    var iter = node.findAll(name, allocator);
    defer iter.deinit();

    while (try iter.next()) |t| {
        try ts.append(try T.init(t, allocator));
    }

    return ts;
}
