#!/bin/bash
# Install dev/test dependencies for audio-tools
set -euo pipefail

echo "=== audio-tools dev setup ==="

# bats
if ! command -v bats &>/dev/null; then
    echo "Installing bats..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y -qq bats
    elif command -v npm &>/dev/null; then
        npm install -g bats
    else
        echo "WARNING: Install bats manually via your package manager or 'npm install -g bats'"
    fi
else
    echo "bats already installed"
fi

# shellcheck
if ! command -v shellcheck &>/dev/null; then
    echo "Installing shellcheck..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y -qq shellcheck
    else
        echo "WARNING: Install shellcheck manually"
    fi
else
    echo "shellcheck already installed"
fi

echo "=== Setup complete ==="
echo "Run: bats tests/bats/"
