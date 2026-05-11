const sol = @import("solana_program_sdk");

fn processInstruction(_: *sol.entrypoint.InstructionContext(2)) sol.ProgramResult {
    sol.log.log("Hello world!");
}

export fn entrypoint(input: [*]u8) u64 {
    return sol.entrypoint.lazyEntrypointMax(2, processInstruction)(input);
}
