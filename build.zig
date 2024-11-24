const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "box2d-raylib-zig",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    //box2D
    const box2d_dep = b.dependency("box2d", .{});
    const box2d_mod = box2d_dep.module("box2d_mod");
    exe.root_module.addImport("box2d", box2d_mod);

    //raylib
    // RAYLIB SDK
    const raylibDependency = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
        // Raylib options
        .rmodels = false,
    });
    const raylibLibrary = raylibDependency.artifact("raylib");
    raylibLibrary.addIncludePath(raylibLibrary.getEmittedIncludeTree());

    // RAYLIB MODULE
    const cstep_raylibModule = b.addTranslateC(.{
        .root_source_file = b.addWriteFiles().add(
            "raylib_includes.h",
            \\#include "raylib.h"
            \\#include "raymath.h"
            \\#include "rlgl.h"
            ,
        ),
        .target = target,
        .optimize = optimize,
    });
    cstep_raylibModule.addIncludePath(raylibLibrary.getEmittedIncludeTree());

    const raylibModule = cstep_raylibModule.createModule();
    raylibModule.linkLibrary(raylibLibrary);

    exe.root_module.addImport("raylib", raylibModule);

    // Copy assets folder
    b.installDirectory(.{
        .source_dir = b.path("assets"),
        .install_dir = .bin,
        .install_subdir = "assets",
    });

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
