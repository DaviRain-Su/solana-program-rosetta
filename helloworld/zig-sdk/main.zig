const sol = @import("solana_program_sdk");

fn processInstruction(_: *sol.entrypoint.InstructionContext) sol.ProgramResult {
    sol.log.log("Hello world!");
}

export fn entrypoint(input: [*]u8) u64 {
    return sol.entrypoint.lazyEntrypoint(processInstruction)(input);
}
