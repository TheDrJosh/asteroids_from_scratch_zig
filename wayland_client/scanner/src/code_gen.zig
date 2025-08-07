pub const std = @import("std");

pub const Struct = struct {
    declorations: std.ArrayList(Decloration),
    field: std.ArrayList(Field),

    pub const Field = struct {
        name: std.ArrayList(u8),
        type: Expretion,
    };
};

pub const Decloration = struct {
    pub const Type = union(enum) {
        function,
        constant,
    };
    doc_comment: std.ArrayList(u8),
    type: Type,
};

pub const Function = struct {
    is_pub: bool,

    name: std.ArrayList(u8),
    args: Args,
    return_type: Expretion,

    body: std.ArrayList(Statement),

    pub const Args = struct {
        name: std.ArrayList(u8),
        type: Expretion,
    };
};

pub const Contant = struct {
    is_pub: bool,
    name: std.ArrayList(u8),
    type: Expretion,
    expr: Expretion,
};

pub const Statement = union(enum) {
    decloration: Decloration,
    expretion: Expretion,
    //if, switch, ect.
};

pub const Expretion = union(enum) {
    string: std.ArrayList(u8),
    identifier: std.ArrayList(u8),
    @"struct": Struct,
    @"enum": Enum,
    struct_init: StructInit,
};

pub const Enum = struct {
    declorations: std.ArrayList(Decloration),

    backing: ?Expretion,
    varient: Varient,

    pub const Varient = struct {
        name: std.ArrayList(u8),
        type: ?Expretion,
    };
};

pub const StructInit = struct {
    type: Expretion,
    fields: std.ArrayList(FieldInit),

    pub const FieldInit = struct {
        name: std.ArrayList(u8),
        value: Expretion,
    };
};
