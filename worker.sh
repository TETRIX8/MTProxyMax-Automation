#!/bin/bash
INSTALL_DIR="/opt/mtproxymax"
POOL_REGULAR="${INSTALL_DIR}/pool_regular.conf"
POOL_TEST="${INSTALL_DIR}/pool_test.conf"
TARGET_COUNT=100
MIN_THRESHOLD=20
REFILL_COUNT=20

generate_secret() {
    openssl rand -hex 16 2>/dev/null || head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n' | head -c 32
}

refill_pool() {
    local pool_file="$1"
    local target="$2"
    local current_count=0
    [ -f "$pool_file" ] && current_count=$(wc -l < "$pool_file")
    local needed=$((target - current_count))
    if [ "$needed" -gt 0 ]; then
        for ((i=0; i<needed; i++)); do generate_secret >> "$pool_file"; done
        chmod 600 "$pool_file"
    fi
}

if [ "$1" == "--daily" ]; then
    refill_pool "$POOL_REGULAR" "$TARGET_COUNT"
    refill_pool "$POOL_TEST" "$TARGET_COUNT"
elif [ "$1" == "--check" ]; then
    reg_count=$(wc -l < "$POOL_REGULAR" 2>/dev/null || echo 0)
    [ "$reg_count" -lt "$MIN_THRESHOLD" ] && for ((i=0; i<REFILL_COUNT; i++)); do generate_secret >> "$POOL_REGULAR"; done
    test_count=$(wc -l < "$POOL_TEST" 2>/dev/null || echo 0)
    [ "$test_count" -lt "$MIN_THRESHOLD" ] && for ((i=0; i<REFILL_COUNT; i++)); do generate_secret >> "$POOL_TEST"; done
fi
