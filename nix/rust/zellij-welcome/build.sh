#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"
cargo build --release

echo "Build complete. Binary at: target/release/zellij-welcome"
