const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const scanner_dep = b.dependency("wayland_scanner", .{
        .target = b.graph.host,
    });

    const scanner_mod = scanner_dep.module("scanner");

    const scanner = b.addExecutable(.{
        .name = "wayland_scanner",
        .root_module = scanner_mod,
    });

    const wayland_protocol_path = b.option(
        std.Build.LazyPath,
        "wayland_protocol_path",
        "path to a valid wayland.xml",
    ) orelse std.Build.LazyPath{
        .cwd_relative = "/usr/share/wayland/wayland.xml",
    };
    const protocol_paths = b.option(
        []const std.Build.LazyPath,
        "protocol_paths",
        "path to a valid wayland protocol xml paths",
    );

    const scanner_step = b.addRunArtifact(scanner);

    const output = scanner_step.addOutputFileArg("protocols.zig");
    scanner_step.addFileArg(wayland_protocol_path);
    if (protocol_paths) |paths| {
        for (paths) |p| {
            scanner_step.addFileArg(p);
        }
    }

    const unix_domain_socket_lib_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    unix_domain_socket_lib_mod.addCSourceFile(.{
        .file = b.path("src/unix_domain_socket_lib/unix_domain_socket_lib.c"),
    });

    const unix_domain_socket_lib = b.addLibrary(.{
        .name = "unix_domain_socket_lib",
        .root_module = unix_domain_socket_lib_mod,
    });

    // This creates a "module", which represents a collection of source files alongside
    // some compilation options, such as optimization mode and linked system libraries.
    // Every executable or library we compile will be based on one or more modules.
    const lib_mod = b.addModule("wayland_client", .{
        // `root_source_file` is the Zig "entry point" of the module. If a module
        // only contains e.g. external object files, you can make this `null`.
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib_mod.linkLibrary(unix_domain_socket_lib);
    lib_mod.addIncludePath(b.path("src/unix_domain_socket_lib/"));

    const protocol_mod = b.createModule(.{
        .root_source_file = output,
        .target = target,
        .optimize = optimize,
    });

    protocol_mod.addImport("wayland_client", lib_mod);

    lib_mod.addImport("protocols", protocol_mod);

    // lib_mod.create("protocols", .{
    //     .root_source_file = output,
    // });

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
