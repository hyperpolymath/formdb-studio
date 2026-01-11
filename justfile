# SPDX-License-Identifier: AGPL-3.0-or-later
# FormDB Studio - Build commands

# Default recipe
default:
    @just --list

# Setup development environment
setup:
    @echo "Setting up FormDB Studio..."
    cd src-tauri && cargo build
    deno cache src/main.ts

# Development mode with hot reload
dev:
    cargo tauri dev

# Build for production
build:
    cargo tauri build

# Run ReScript compiler in watch mode
rescript-watch:
    deno run -A npm:rescript build -w

# Type check Lean 4 proofs
check-proofs:
    cd ../fqldt && lake build

# Format code
fmt:
    deno fmt src/
    cd src-tauri && cargo fmt

# Lint
lint:
    deno lint src/
    cd src-tauri && cargo clippy

# Clean build artifacts
clean:
    rm -rf build/
    cd src-tauri && cargo clean
