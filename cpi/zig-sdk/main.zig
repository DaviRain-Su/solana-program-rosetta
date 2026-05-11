const std = @import("std");
const sol = @import("solana_program_sdk");

const SIZE: u64 = 42;
const system_program_id: sol.Pubkey = .{0} ** 32;

extern fn sol_create_program_address(
    seeds_ptr: [*]const []const u8,
    seeds_len: u64,
    program_id_ptr: *const sol.Pubkey,
    address_ptr: *sol.Pubkey,
) callconv(.c) u64;

fn processInstruction(context: *sol.entrypoint.InstructionContext(2)) sol.ProgramResult {
    if (sol.entrypoint.unlikely(context.remaining() != 2)) {
        return error.NotEnoughAccountKeys;
    }

    const allocated = context.nextAccountEx(.unchecked);
    const system_program = context.nextAccountEx(.unchecked);
    const ix_data = context.instructionData();
    if (ix_data.len < 1) return error.InvalidInstructionData;

    const signer_seed_bytes = [1]u8{ix_data[0]};
    const signer_seeds = [_][]const u8{ "You pass butter", &signer_seed_bytes };
    var expected_allocated_key: sol.Pubkey = undefined;
    if (sol_create_program_address(&signer_seeds, signer_seeds.len, context.programId(), &expected_allocated_key) != 0) {
        return error.InvalidSeeds;
    }

    if (!sol.pubkey.pubkeyEq(allocated.key(), &expected_allocated_key)) return error.InvalidArgument;
    if (!sol.pubkey.pubkeyEq(system_program.key(), &system_program_id)) return error.InvalidArgument;

    const metas = [_]sol.cpi.AccountMeta{
        .{ .pubkey = allocated.key(), .is_writable = true, .is_signer = true },
    };

    var data: [12]u8 = undefined;
    std.mem.writeInt(u32, data[0..4], @intFromEnum(sol.system.SystemInstruction.Allocate), .little);
    std.mem.writeInt(u64, data[4..12], SIZE, .little);

    const instruction = sol.cpi.Instruction{
        .program_id = &system_program_id,
        .accounts = &metas,
        .data = &data,
    };

    const infos = [_]sol.AccountInfo{ allocated, system_program };
    try sol.cpi.invokeSigned(&instruction, &infos, &signer_seeds);
}

export fn entrypoint(input: [*]u8) u64 {
    return sol.entrypoint.lazyEntrypointMax(2, processInstruction)(input);
}
