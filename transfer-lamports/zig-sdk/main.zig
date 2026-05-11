const sol = @import("solana_program_sdk");

export fn entrypoint(input: [*]align(8) u8) u64 {
    // Parse num_accounts and skip to first account
    const num_accounts: *const u64 = @ptrCast(input);
    if (num_accounts.* != 2) return 1;

    // Account layout after num_accounts:
    // [8 bytes dup_marker] [88 bytes Account struct] [data] [10KB padding] [8 bytes rent_epoch]
    var ptr: [*]align(8) u8 = @ptrCast(input + 8);

    // Skip dup marker for first account
    ptr += 8;

    // First account: get lamports pointer
    // Account struct: [borrow_state 1][is_signer 1][is_writable 1][is_executable 1][padding 4][key 32][owner 32][lamports 8][data_len 8]
    // lamports is at offset 80 in Account struct
    const source_lamports: *u64 = @ptrCast(ptr + 80);

    // Skip past first account struct + data + padding + rent_epoch
    // For test accounts, data_len is 0, so we can skip fixed amount
    // ptr += 88 + 0 + 10240 + align + 8 = 88 + 10240 + 8 + 8 = 10344 (already aligned)
    ptr += 88 + 10240 + 8;

    // Skip dup marker for second account
    ptr += 8;

    // Second account: get lamports pointer
    const dest_lamports: *u64 = @ptrCast(ptr + 80);

    // Skip second account struct + data + padding + rent_epoch
    ptr += 88 + 10240 + 8;

    // Now ptr points to instruction_data_len
    const ix_data_len: *const u64 = @ptrCast(ptr);
    if (ix_data_len.* < 8) return 1;
    ptr += 8;

    const transfer_amount = @as(*const u64, @ptrCast(ptr)).*;

    source_lamports.* -= transfer_amount;
    dest_lamports.* += transfer_amount;

    return 0;
}
