const sol = @import("solana_program_sdk");

fn processInstruction(context: *sol.entrypoint.InstructionContext) sol.ProgramResult {
    if (context.remaining() < 1) return error.NotEnoughAccountKeys;

    const account = context.nextAccountEx(.unchecked);
    if (!sol.pubkey.pubkeyEqAligned(account.key(), account.owner())) {
        return error.InvalidArgument;
    }
}

export fn entrypoint(input: [*]u8) u64 {
    return sol.entrypoint.lazyEntrypoint(processInstruction)(input);
}
