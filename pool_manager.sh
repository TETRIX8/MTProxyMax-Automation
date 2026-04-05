#!/bin/bash
INSTALL_DIR="/opt/mtproxymax"
POOL_REGULAR="${INSTALL_DIR}/pool_regular.conf"
POOL_TEST="${INSTALL_DIR}/pool_test.conf"
WORKER_SCRIPT="${INSTALL_DIR}/worker.sh"

get_key_from_pool() {
    local pool_file="$1"
    [ ! -s "$pool_file" ] && return 1
    local key=$(head -n 1 "$pool_file")
    sed -i '1d' "$pool_file"
    bash "$WORKER_SCRIPT" --check &
    echo "$key"
}

issue_test_key() {
    local label="test_$(date +%s)"
    local key=$(get_key_from_pool "$POOL_TEST") || return 1
    local expiry=$(date -d "+1 day" +%Y-%m-%d)
    mtproxymax secret add "$label" "$key" "true" > /dev/null
    mtproxymax secret setlimits "$label" 15 5 0 "$expiry" > /dev/null
    echo "Test key issued: $label"
}

issue_regular_key() {
    local label="$1"
    local period="$2"
    local key=$(get_key_from_pool "$POOL_REGULAR") || return 1
    local expiry="0"
    [ -n "$period" ] && expiry=$(date -d "$period" +%Y-%m-%d)
    mtproxymax secret add "$label" "$key" "true" > /dev/null
    [ "$expiry" != "0" ] && mtproxymax secret setlimits "$label" 15 5 0 "$expiry" > /dev/null
    echo "Regular key issued: $label"
}

case "$1" in
    get-test) issue_test_key ;;
    get-regular) issue_regular_key "$2" "$3" ;;
esac
