#!/usr/bin/env bash

set -euo pipefail

PROGRAM_NAME="$1"
PARAMS=("$@")
ROOT_DIR="$(cd "$(dirname "$0")"; pwd)"
PROGRAM_DIR="$ROOT_DIR/$PROGRAM_NAME"
ZIG="${SOLANA_ZIG:-${ZIG:-}}"

if [[ -z "$ZIG" ]]; then
  echo "Set SOLANA_ZIG to the solana-zig fork v1.53.0 executable." >&2
  echo "Example: export SOLANA_ZIG=/path/to/zig-x86_64-linux-musl-baseline/zig" >&2
  exit 1
fi

if [[ ! -d "$PROGRAM_DIR/zig-sdk" ]]; then
  echo "zig-sdk implementation not found for $PROGRAM_NAME" >&2
  exit 1
fi

cd "$PROGRAM_DIR/zig-sdk"
"$ZIG" build --summary all -freference-trace 2>&1 \
  | sed -E '/[+-](jmp-ext|store-imm).*not a recognized feature/d'
SBF_OUT_DIR="$PROGRAM_DIR/zig-sdk/zig-out/lib" cargo test --manifest-path "$PROGRAM_DIR/Cargo.toml" "${PARAMS[@]:1}"
