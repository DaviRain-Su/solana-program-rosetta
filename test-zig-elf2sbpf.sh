#!/usr/bin/env bash

set -euo pipefail

PROGRAM_NAME="$1"
PARAMS=("$@")
ROOT_DIR="$(cd "$(dirname "$0")"; pwd)"
PROGRAM_DIR="$ROOT_DIR/$PROGRAM_NAME"
ZIG="${ZIG:-zig}"
ELF2SBPF_BIN="${ELF2SBPF_BIN:-$ROOT_DIR/../elf2sbpf/zig-out/bin/elf2sbpf}"

if [[ ! -x "$ELF2SBPF_BIN" ]]; then
  if [[ -d "$ROOT_DIR/../elf2sbpf/.git" ]]; then
    (
      cd "$ROOT_DIR/../elf2sbpf"
      zig build
    )
  fi
fi

if [[ ! -x "$ELF2SBPF_BIN" ]]; then
  echo "elf2sbpf not found: $ELF2SBPF_BIN" >&2
  echo "Set ELF2SBPF_BIN or clone ../elf2sbpf first." >&2
  exit 1
fi

cd "$PROGRAM_DIR/zig-elf2sbpf"
"$ZIG" build -Delf2sbpf-bin="$ELF2SBPF_BIN" --summary all -freference-trace --verbose
SBF_OUT_DIR="$PROGRAM_DIR/zig-elf2sbpf/zig-out/lib" cargo test --manifest-path "$PROGRAM_DIR/Cargo.toml" "${PARAMS[@]:1}"
