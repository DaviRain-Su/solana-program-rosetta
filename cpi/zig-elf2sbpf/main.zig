const std = @import("std");
const sol = @import("solana_program_sdk");

const SIZE: u64 = 42;
const system_program_id = sol.public_key.PublicKey.comptimeFromBase58("11111111111111111111111111111111");

// This comparison variant encodes the Allocate CPI directly so it can stay on
// the stock-Zig + elf2sbpf path without pulling in a second SDK copy via
// solana_program_library.
export fn entrypoint(input: [*]u8) u64 {
    const context = sol.context.Context.load(input) catch return 1;
    const allocated = context.accounts[0];
    const system_program = context.accounts[1];

    var expected_allocated_key: sol.public_key.PublicKey = undefined;
    const signer_seed_bytes = [1]u8{context.data[0]};
    const address_seeds = [_][]const u8{ "You pass butter", &signer_seed_bytes };
    const create_program_address = struct {
        extern fn sol_create_program_address(
            seeds_ptr: [*]const []const u8,
            seeds_len: u64,
            program_id_ptr: *const sol.public_key.PublicKey,
            address_ptr: *sol.public_key.PublicKey,
        ) callconv(.c) u64;
    }.sol_create_program_address;
    if (create_program_address(&address_seeds, address_seeds.len, context.program_id, &expected_allocated_key) != 0) return 1;

    if (!allocated.id().equals(expected_allocated_key)) return 1;
    if (!system_program.id().equals(system_program_id)) return 1;

    const metas = [_]sol.account.Account.Param{
        .{ .id = &allocated.ptr.id, .is_writable = true, .is_signer = true },
    };
    var data: [12]u8 = undefined;
    std.mem.writeInt(u32, data[0..4], 8, .little);
    std.mem.writeInt(u64, data[4..12], SIZE, .little);
    const instruction = sol.instruction.Instruction.from(.{
        .program_id = &system_program_id,
        .accounts = &metas,
        .data = &data,
    });
    const infos = [_]sol.account.Account.Info{allocated.info(), system_program.info()};
    const signer_seed_group = [_][]const u8{ "You pass butter", &signer_seed_bytes };
    const signer_seeds = [_][]const []const u8{&signer_seed_group};

    instruction.invokeSigned(&infos, &signer_seeds) catch return 1;
    return 0;
}
