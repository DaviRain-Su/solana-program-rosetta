const std = @import("std");
const sdk_build = @import("solana_program_sdk");

pub fn build(b: *std.Build) !void {
    const target = b.resolveTargetQuery(sdk_build.bpf_target);
    const optimize = .ReleaseFast;
    const dep_opts = .{ .target = target, .optimize = optimize };
    const elf2sbpf_bin = b.option([]const u8, "elf2sbpf-bin", "Path to the elf2sbpf executable");

    const sdk_dep = b.dependency("solana_program_sdk", dep_opts);
    const sdk_mod = sdk_dep.module("solana_program_sdk");

    const program_mod = b.createModule(.{
        .root_source_file = b.path("main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "solana_program_sdk", .module = sdk_mod },
        },
    });
    program_mod.pic = true;
    program_mod.strip = true;

    const bitcode_obj = b.addObject(.{
        .name = "solana_program_rosetta_cpi-bitcode",
        .root_module = program_mod,
    });
    const bitcode = bitcode_obj.getEmittedLlvmBc();

    const zig_cc = b.addSystemCommand(&.{
        b.graph.zig_exe,
        "cc",
        "-target",
        "bpfel-freestanding",
        "-mcpu=v2",
        "-O2",
        "-mllvm",
        "-bpf-stack-size=4096",
        "-c",
    });
    zig_cc.addFileArg(bitcode);
    zig_cc.addArg("-o");
    const obj = zig_cc.addOutputFileArg("solana_program_rosetta_cpi.o");

    const resolved_elf2sbpf = sdk_build.resolveElf2sbpfBin(b, elf2sbpf_bin);
    const link_program = b.addSystemCommand(&.{resolved_elf2sbpf});
    link_program.addFileArg(obj);
    const so = link_program.addOutputFileArg("solana_program_rosetta_cpi.so");

    b.getInstallStep().dependOn(&b.addInstallLibFile(so, "solana_program_rosetta_cpi.so").step);
}
