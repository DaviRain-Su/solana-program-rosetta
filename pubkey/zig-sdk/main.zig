const sol = @import("solana_program_sdk");

export fn entrypoint(input: [*]align(8) u8) u64 {
    // Skip num_accounts (8 bytes) + dup_marker (8 bytes)
    const account_start = input + 16;
    const key: *const sol.Pubkey = @ptrCast(account_start);
    const owner: *const sol.Pubkey = @ptrCast(account_start + 32);

    if (!sol.pubkey.pubkeyEqAligned(key, owner)) {
        return 1;
    }

    return 0;
}
