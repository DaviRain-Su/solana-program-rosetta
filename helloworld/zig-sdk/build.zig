const std = @import("std");
const solana = @import("solana_program_sdk");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .sbf,
        .os_tag = .solana,
    });
    const optimize = .ReleaseFast;

    const solana_dep = b.dependency("solana_program_sdk", .{
        .target = target,
        .optimize = optimize,
    });
    const solana_mod = solana_dep.module("solana_program_sdk");

    const program_mod = b.createModule(.{
        .root_source_file = b.path("main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "solana_program_sdk", .module = solana_mod },
        },
    });
    program_mod.pic = true;
    program_mod.strip = true;

    const program = b.addLibrary(.{
        .name = "solana_program_rosetta_helloworld",
        .linkage = .dynamic,
        .root_module = program_mod,
    });
    program.entry = .{ .symbol_name = "entrypoint" };
    program.stack_size = 4096;
    program.link_z_notext = true;
    solana.linkSolanaProgram(b, program);
    b.installArtifact(program);
}
