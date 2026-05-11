const std = @import("std");
const solana = @import("solana_program_sdk");

pub fn build(b: *std.Build) void {
    _ = solana.buildProgram(b, .{
        .name = "solana_program_rosetta_pubkey",
        .root_source_file = b.path("main.zig"),
    });
}
