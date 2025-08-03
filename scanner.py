import xml.etree.ElementTree as ET

protocols = [
    "/usr/share/wayland/wayland.xml",
    "/usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml",
    "/usr/share/wayland-protocols/unstable/xdg-decoration/xdg-decoration-unstable-v1.xml",
]


def main():
    protocols_zig = open("./src/wayland/protocols.zig", "w")

    for protocol in protocols:
        tree = ET.parse(protocol)

        root = tree.getroot()

        protocol_name = root.attrib["name"]

        comment = "# " + protocol_name

        description = getDescription(root)

        if description is not None:
            comment += "\n\n" + description

        # copyright_node = root.find("copyright")

        # if copyright_node is not None:
        #     if copyright_node.text is not None:
        #         comment += "\n\n## Copyright\n" + copyright_node.text.replace(
        #             "\t", "    "
        #         )

        protocols_zig.write(
            makeDocComment(comment)
            + "\nconst "
            + escapeKeyword(protocol_name)
            + ' = @import("'
            + protocol_name
            + '.zig");\n\n'
        )

        zig_file = open("./src/wayland/protocols/" + protocol_name + ".zig", "w")

        zig_file.write('const std = @import("std");\n')
        zig_file.write('const WaylandRuntime = @import("../WaylandRuntime.zig");\n')
        zig_file.write('const wayland_types = @import("../wayland_types.zig");\n')

        for interface_node in root.findall("./interface"):
            interface_name = interface_node.attrib["name"]
            interface_version = interface_node.attrib["version"]

            description = getDescription(interface_node)

            zig_file.write("\n")

            if description is not None:
                zig_file.write(
                    makeDocComment(
                        "# " + interface_node.attrib["name"] + "\n\n" + description
                    )
                    + "\n"
                )

            zig_file.write(
                "pub const " + escapeKeyword(interface_name) + " = struct {\n"
            )
            zig_file.write("    pub const interface = \"" + interface_name + "\";\n")
            zig_file.write("    pub const version = " + interface_version + ";\n")

            zig_file.write("\n    pub const enums = struct{")

            for enum in interface_node.findall("./enum"):
                description = getDescription(enum)

                zig_file.write("\n")

                if description is not None:
                    zig_file.write(
                        makeDocComment(
                            "# " + enum.attrib["name"] + "\n\n" + description, 2
                        )
                        + "\n"
                    )

                zig_file.write(
                    "        pub const "
                    + escapeKeyword(enum.attrib["name"])
                    + " = enum(u32) {\n"
                )

                for entry in enum.findall("./entry"):
                    description = getDescription(entry)

                    if description is not None:
                        zig_file.write(
                            makeDocComment(
                                "# " + entry.attrib["name"] + "\n\n" + description, 3
                            )
                            + "\n"
                        )

                    zig_file.write(
                        "            "
                        + escapeKeyword(entry.attrib["name"])
                        + " = "
                        + entry.attrib["value"]
                        + ",\n"
                    )
                zig_file.write("        };\n")

            zig_file.write("    };\n")

            zig_file.write("\n    object_id: u32,\n    runtime: *WaylandRuntime,\n")

            opcode = 0
            
            for request in interface_node.findall("./request"):
                description = getDescription(request)

                zig_file.write("\n")

                comment = "# " + request.attrib["name"] + "\n\n"

                if description is not None:
                    comment += description

                comment += "\n## Args \n\n"

                for arg in request.findall("./arg"):
                    comment += "### " + arg.attrib["name"] + "\n\n"

                    comment += "#### Type\n\n    " + arg.attrib["type"] + "\n\n"

                    if "summary" in arg.attrib:
                        comment += (
                            "#### Summary\n\n    " + arg.attrib["summary"] + "\n\n"
                        )

                    if "interface" in arg.attrib:
                        comment += (
                            "#### Interface\n\n    " + arg.attrib["interface"] + "\n\n"
                        )
                    if "allow-null" in arg.attrib:
                        comment += (
                            "#### Allow Null\n\n    "
                            + arg.attrib["allow-null"]
                            + "\n\n"
                        )
                    if "enum" in arg.attrib:
                        comment += "#### Enum\n\n    " + arg.attrib["enum"] + "\n\n"

                zig_file.write(makeDocComment(comment, 1) + "\n")

                zig_file.write(
                    "    pub fn "
                    + escapeKeyword(request.attrib["name"])
                    + "(self: *const "
                    + interface_name
                )

                new_ids = []

                for arg in request.findall("./arg"):
                    if arg.attrib["type"] == "new_id":
                        if "interface" not in arg.attrib:
                            zig_file.write(", " + arg.attrib["name"] + ": type")
                        new_ids.append((arg.attrib["name"], arg.attrib.get("interface")))
                        continue

                    zig_file.write(", " + arg.attrib["name"] + ": ")
                    #TODO - Enum Support
                    #TODO - Optional support
                    if arg.attrib["type"] == "int":
                        zig_file.write("i32")
                    elif arg.attrib["type"] == "uint":
                        zig_file.write("u32")
                    elif arg.attrib["type"] == "object":
                        zig_file.write("wayland_types.ObjectId")
                    elif arg.attrib["type"] == "string":
                        zig_file.write("[]const u8")
                    elif arg.attrib["type"] == "array":
                        zig_file.write("[]const u8")
                    elif arg.attrib["type"] == "fixed":
                        zig_file.write("wayland_types.Fixed")
                    elif arg.attrib["type"] == "fd":
                        zig_file.write("wayland_types.Fd")                        
                    else:
                        print("unsuported type. type = " + arg.attrib["type"])

                zig_file.write(") !")
                
                if len(new_ids) == 0:
                    zig_file.write("void")
                else:
                    zig_file.write("struct { ")
                    for new_id in new_ids:
                        if new_id[1] is None:
                            zig_file.write(new_id[0] + ": " + new_id[0] + ", ")
                        else:
                            zig_file.write(new_id[0] + ": " + new_id[1] + ", ")
                    zig_file.write("}")
                
                zig_file.write(" {\n")
                
                for new_id in new_ids:
                    zig_file.write("        const " + new_id[0] + "_id = self.runtime.getId();\n" )
                
                zig_file.write("        try self.runtime.sendRequest(self.object_id, " + str(opcode) + ", .{")
                
                for arg in request.findall("./arg"):
                    if arg.attrib["type"] == "string":
                        zig_file.write("wayland_types.String{.data = " + arg.attrib["name"] + "}, ")
                    elif arg.attrib["type"] == "new_id":
                        if "interface" not in arg.attrib:
                            zig_file.write("wayland_types.NewId{.interface = " + arg.attrib["name"] + ".interface, .version = " + arg.attrib["name"] + ".version, .id = " + arg.attrib["name"] + "_id, }, ")
                        else:
                            zig_file.write(arg.attrib["name"] + "_id, ")
                    else:
                     zig_file.write(arg.attrib["name"] + ", ")
                     
                zig_file.write("});\n")
                
                if len(new_ids) != 0:
                    #TODO - len == 1 case
                    zig_file.write("        return .{")
                    for new_id in new_ids:
                        if new_id[1] is not None:
                            zig_file.write("." + new_id[0] + " = " + new_id[1] + "{.object_id = " + new_id[0] + "_id, .runtime = self.runtime}, ")
                        else:
                            zig_file.write("." + new_id[0] + " = " + new_id[0] + "{.object_id = " + new_id[0] + "_id, .runtime = self.runtime}, ")
                    zig_file.write("};\n")
                    
                
                zig_file.write("    }\n")
                opcode += 1
                

                
            opcode = 0
            for event in interface_node.findall("./event"):
                description = getDescription(event)

                zig_file.write("\n")

                comment = "# " + event.attrib["name"] + "\n\n"

                if description is not None:
                    comment += description

                comment += "\n## Args \n\n"

                for arg in event.findall("./arg"):
                    comment += "### " + arg.attrib["name"] + "\n\n"

                    comment += "#### Type\n\n    " + arg.attrib["type"] + "\n\n"

                    if "summary" in arg.attrib:
                        comment += (
                            "#### Summary\n\n    " + arg.attrib["summary"] + "\n\n"
                        )

                    if "interface" in arg.attrib:
                        comment += (
                            "#### Interface\n\n    " + arg.attrib["interface"] + "\n\n"
                        )
                    if "allow-null" in arg.attrib:
                        comment += (
                            "#### Allow Null\n\n    "
                            + arg.attrib["allow-null"]
                            + "\n\n"
                        )
                    if "enum" in arg.attrib:
                        comment += "#### Enum\n\n    " + arg.attrib["enum"] + "\n\n"

                zig_file.write(makeDocComment(comment, 1) + "\n")

                zig_file.write(
                    "    pub fn "
                    + escapeKeyword("next_" + event.attrib["name"])
                    + "(self: *const " + interface_name + ") !?struct {"
                )
                
                for arg in event.findall("./arg"):
                    zig_file.write(arg.attrib["name"] + ": ")
                    if arg.attrib["type"] == "int":
                        zig_file.write("i32, ")
                    elif arg.attrib["type"] == "uint":
                        zig_file.write("u32, ")
                    elif arg.attrib["type"] == "array":
                        zig_file.write("std.ArrayList(u8), ")
                    elif arg.attrib["type"] == "string":
                        zig_file.write("wayland_types.String, ")
                    elif arg.attrib["type"] == "fixed":
                        zig_file.write("wayland_types.Fixed, ")
                    elif arg.attrib["type"] == "object":
                        zig_file.write("wayland_types.ObjectId, ")
                    elif arg.attrib["type"] == "fd":
                        zig_file.write("wayland_types.Fd, ")
                    elif arg.attrib["type"] == "new_id":
                        #TODO - do propperly
                        zig_file.write("wayland_types.ObjectId, ")
                    else:
                        print("unsuported type. type = " + arg.attrib["type"])

                        
                
                zig_file.write("} {\n")
                
                zig_file.write("        return try self.runtime.next(self.object_id, " + str(opcode) + ", @typeInfo(@typeInfo(@typeInfo(@TypeOf(next_" + event.attrib["name"] + ")).@\"fn\".return_type.?).error_union.payload).optional.child);\n")
                
                zig_file.write("}\n")
                
                opcode += 1

            zig_file.write("};\n")


def makeDocComment(str: str, indent: int = 0):
    return "    " * indent + "/// " + str.replace("\n", "\n" + "    " * indent + "/// ")


def getDescription(node: ET.Element, header_level: int = 2):
    description_node = node.find("./description")

    if description_node is None:
        return None

    summary = description_node.attrib["summary"]

    description = description_node.text

    if description is None or description.strip() == "":
        return summary

    return (
        "#" * header_level
        + " Summary\n\n    "
        + summary
        + "\n\n"
        + "#" * header_level
        + " Description\n"
        + description.replace("\t", "    ")
    )


def escapeKeyword(str: str):
    if str in [
        "addrspace",
        "align",
        "allowzero",
        "and",
        "anyframe",
        "anytype",
        "asm",
        "async",
        "await",
        "break",
        "callconv",
        "catch",
        "comptime",
        "const",
        "continue",
        "defer",
        "else",
        "enum",
        "errdefer",
        "error",
        "export",
        "extern",
        "fn",
        "inline",
        "linksection",
        "noalias",
        "noline",
        "nosuspend",
        "opaque",
        "or",
        "orelse",
        "packed",
        "pub",
        "resume",
        "return",
        "struct",
        "suspend",
        "switch",
        "test",
        "threadlocal",
        "try",
        "union",
        "unreachable",
        "usingnamespace",
        "var",
        "volatile",
        "while",
        "type",
    ]:
        return '@"' + str + '"'

    if str.startswith(("0", "1", "2", "3", "4", "5", "6", "7", "8", "9")):
        return '@"' + str + '"'

    return str


if __name__ == "__main__":
    main()
