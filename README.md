# solana-program-rosetta

Multiple implementations of Solana programs across languages: Rust, Zig, C, and
even assembly.

More programs will be added over time!

## Getting started

### Prerequisite for all languages

* Install Rust: https://www.rust-lang.org/tools/install

### Rust

* Install Solana tools

```console
./install-solana.sh
```

* Go to a program directory

```console
cd helloworld
```

* Build a program

```console
cargo build-sbf
```

* Test a program

```console
cargo test-sbf
```

### Zig

#### Original `solana-zig` path

* Get the compiler

```console
./install-solana-zig.sh
```

* Go to the Zig implementation of a program

```console
cd helloworld/zig
```

* Build the program

```console
../../solana-zig/zig build
```

* Test it

```console
cd ..
SBF_OUT_DIR="./zig/zig-out/lib" cargo test
```

* OR use the helper from the root of this repo to build and test

```console
./test-zig.sh helloworld
```

#### Stock Zig + `elf2sbpf` comparison path

This repo also includes comparison builds for a subset of Zig programs using:

- stock Zig 0.16
- `solana-program-sdk-zig` pinned to the `solana-zig-fork-0.16` branch
  (commit `5b74dc78948d68640aa21d62d882d6c4b0e23af8`); that SDK exposes
  both `buildProgram` (solana-zig fork path) and `buildProgramElf2sbpf`
  (stock Zig path) — these dirs use the latter
- `elf2sbpf` as the final ELF `.o` → Solana `.so` post-processor

Currently wired programs:

- `helloworld`
- `pubkey`
- `transfer-lamports`
- `cpi`
- `token`

Expected local tool setup:

```text
../elf2sbpf
```

The Zig package dependency on `solana-program-sdk-zig` is fetched automatically
from GitHub; only the `elf2sbpf` binary itself is expected locally by default
unless you set `ELF2SBPF_BIN` explicitly.

Then run:

```console
./test-zig-elf2sbpf.sh helloworld
./test-zig-elf2sbpf.sh pubkey
./test-zig-elf2sbpf.sh transfer-lamports
./test-zig-elf2sbpf.sh cpi
./test-zig-elf2sbpf.sh token
```

These tests reuse each program's existing Rust functional tests. For `token`,
the per-instruction CU numbers below were re-checked with the existing
`assert_instruction_count` integration tests.

##### Enabling the `--peephole` optimizer

`elf2sbpf` ≥ D.7.10 ships an opt-in bytecode-level peephole pass
(`--peephole` flag) that recovers most of the CU gap between stock
Zig and `solana-zig` by collapsing `bpfel -O2`'s byte-wise `load/store
i64 align 1` expansions back into single `ldxdw`/`stxdw` instructions.
The flag is **off by default** — output is then byte-identical to
`reference-shim`. Because `test-zig-elf2sbpf.sh` calls `elf2sbpf` via
the SDK's `build.zig` (which doesn't know about the flag), the
easiest way to enable it for a full cargo-test run is to point
`ELF2SBPF_BIN` at a wrapper script:

```console
cat > /tmp/elf2sbpf-peephole.sh <<'EOF'
#!/usr/bin/env bash
exec /path/to/elf2sbpf --peephole "$@"
EOF
chmod +x /tmp/elf2sbpf-peephole.sh

ELF2SBPF_BIN=/tmp/elf2sbpf-peephole.sh ./test-zig-elf2sbpf.sh token
```

The CU columns labeled "Zig (stock Zig + elf2sbpf `--peephole`)"
below show the numbers measured with this wrapper. See
[`DaviRain-Su/elf2sbpf`](https://github.com/DaviRain-Su/elf2sbpf)
§D.7.10 for the full design and scope.

#### Using a modern Zig 0.16 with `solana-zig` baseline CU

The `solana-zig` tarball fetched by `install-solana-zig.sh` is the
officially-published Zig 0.13-based build that pins `joncinque/llvm-project-solana`.
If you instead want a **modern Zig 0.16 language** while still hitting
the same optimal CU numbers as the `Zig` column above, there's a WIP
fork of `solana-zig-bootstrap` that ports Zig forward to
`0.16.0-dev.0+cf5f8113c` against the same LLVM 20 fork:

```console
git clone -b solana-1.52-zig0.16 \
  https://github.com/DaviRain-Su/solana-zig-bootstrap \
  ../solana-zig-bootstrap
cd ../solana-zig-bootstrap
git submodule update --init --recursive
./build native-macos-none baseline   # or native-linux-musl baseline
```

Then run `test-zig.sh` with the `ZIG` env var pointing at the fork:

```console
ZIG=../solana-zig-bootstrap/out-smoke/host/bin/zig ./test-zig.sh token
```

CU numbers are identical to the `Zig` column — the fork's output goes
through the same SBF LLVM target; only the Zig compiler frontend
language level changes.

### C

* Install Solana C compiler

```console
./install-solana-c.sh
```

* Install Solana tools

```console
./install-solana.sh
```

* Go to a program directory

```console
cd helloworld/c
```

* Build a program

```console
make
```

* Test it

```console
cd ..
SBF_OUT_DIR="./c/out" cargo test
```

* OR use the helper from the root of this repo to build and test

```console
./test-c.sh helloworld
```

### Assembly

* Install Solana LLVM tools

```console
./install-solana-llvm.sh
```

* Go to a program directory

```console
cd helloworld/asm
```

* Build a program

```console
make
```

* Test it

```console
cd ..
SBF_OUT_DIR="./asm/out" cargo test
```

* OR use the helper from the root of this repo to build and test

```console
./test-asm.sh helloworld
```

## Current Programs

### Helloworld

Logs a static string using the `sol_log_` syscall.

| Language | CU Usage |
| --- | --- |
| Rust | 105 |
| Zig | 105 |
| Zig (stock Zig + elf2sbpf framework) | 105 |
| Zig (stock Zig + elf2sbpf `--peephole`) | 105 |
| C | 105 |
| Assembly | 104 |

Since this is just doing a syscall, all the languages behave the same. The only
difference is that the Assembly version *doesn't* set the return code to 0, and
lets the VM assume it worked.

### Transfer-Lamports

Moves lamports from a source account to a destination, with the amount given by
a little-endian u64 in instruction data.

| Language | CU Usage |
| --- | --- |
| Rust | 459 |
| Zig | 37 |
| Zig (stock Zig + elf2sbpf framework) | 60 |
| Zig (stock Zig + elf2sbpf `--peephole`) | 39 |
| C | 104 |
| Assembly | 30 |
| Rust (pinocchio) | 27 |

This one starts to get interesting since it requires parsing the instruction
input. Since the assembly version knows exactly where to find everything, it can
be hyper-optimized. The pinocchio version performs better than the assembly
implementation!

### CPI

Allocates a PDA given by the seed "You pass butter" and a bump seed in the
instruction data. This requires a call to `create_program_address` to check the
address and `invoke_signed` to CPI to the system program.

| Language | CU Usage | CU Usage (minus syscalls) |
| --- | --- | --- |
| Rust | 3698 | 1198 |
| Zig | 2967 | 309 |
| Zig (stock Zig + elf2sbpf framework) | 2818 | 318 |
| Zig (stock Zig + elf2sbpf `--peephole`) | 2818 | 318 |
| C | 3122 | 622 |
| Rust (pinocchio) | 2771 | 271 |

Note: `create_program_address` consumes 1500 CUs, and `invoke` consumes 1000, so
we can subtract 2500 CUs from each program to see the actual cost of the program
logic.

### Pubkey

A program to compare two `Pubkey` instances. This operation is very common in
on-chain programs, but it can be expensive.

| Language | CU Usage |
| --- | --- |
| Rust | 14 |
| Zig | 15 |
| Zig (stock Zig + elf2sbpf framework) | 187 |
| Zig (stock Zig + elf2sbpf `--peephole`) | 19 |

### Token

A reduced instruction set from SPL-Token. Includes an entrypoint, instruction
deserialization, and account serde. The Rust version is the full SPL Token
program.

  * Initialize Mint

| Language | CU Usage |
| --- | --- |
| Rust | 1115 |
| Zig | 142 |
| Zig (stock Zig + elf2sbpf framework) | 516 |
| Zig (stock Zig + elf2sbpf `--peephole`) | 348 |

  * Initialize Account

| Language | CU Usage |
| --- | --- |
| Rust | 2071 |
| Zig | 158 |
| Zig (stock Zig + elf2sbpf framework) | 491 |
| Zig (stock Zig + elf2sbpf `--peephole`) | 365 |

  * Mint To

| Language | CU Usage |
| --- | --- |
| Rust | 2189 |
| Zig | 133 |
| Zig (stock Zig + elf2sbpf framework) | 448 |
| Zig (stock Zig + elf2sbpf `--peephole`) | 364 |

  * Transfer

| Language | CU Usage |
| --- | --- |
| Rust | 2208 |
| Zig | 124 |
| Zig (stock Zig + elf2sbpf framework) | 572 |
| Zig (stock Zig + elf2sbpf `--peephole`) | 486 |

  * Burn

| Language | CU Usage |
| --- | --- |
| Rust | 2045 |
| Zig | 123 |
| Zig (stock Zig + elf2sbpf framework) | 452 |
| Zig (stock Zig + elf2sbpf `--peephole`) | 280 |

  * Close Account

| Language | CU Usage |
| --- | --- |
| Rust | 1483 |
| Zig | 114 |
| Zig (stock Zig + elf2sbpf framework) | 236 |
| Zig (stock Zig + elf2sbpf `--peephole`) | 194 |
