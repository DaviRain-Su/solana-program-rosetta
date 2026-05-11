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

#### Using a modern Zig 0.16 with `solana-zig` baseline CU

The `solana-zig` tarball fetched by `install-solana-zig.sh` is the
officially-published Zig 0.13-based build that pins `joncinque/llvm-project-solana`.
If you instead want a **modern Zig 0.16 language** while still hitting
the same optimal CU numbers as the `Zig` column above, there's a WIP
fork of `solana-zig-bootstrap` that ports Zig forward to
`0.16.0-dev.0+cf5f8113c` against the same LLVM 20 fork:

```console
git clone -b solana-1.53-zig0.16 \
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

### Token

A reduced instruction set from SPL-Token. Includes an entrypoint, instruction
deserialization, and account serde. The Rust version is the full SPL Token
program.

  * Initialize Mint

| Language | CU Usage |
| --- | --- |
| Rust | 1115 |
| Zig | 142 |

  * Initialize Account

| Language | CU Usage |
| --- | --- |
| Rust | 2071 |
| Zig | 158 |

  * Mint To

| Language | CU Usage |
| --- | --- |
| Rust | 2189 |
| Zig | 133 |

  * Transfer

| Language | CU Usage |
| --- | --- |
| Rust | 2208 |
| Zig | 124 |

  * Burn

| Language | CU Usage |
| --- | --- |
| Rust | 2045 |
| Zig | 123 |

  * Close Account

| Language | CU Usage |
| --- | --- |
| Rust | 1483 |
| Zig | 114 |
