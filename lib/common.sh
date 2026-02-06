#!/bin/bash
# Shared utilities for upgrade scripts

# =============================================================================
# Utility Functions
# =============================================================================

die() {
    echo "Error: $1" >&2
    exit 1
}

log() {
    echo "[orbit-actions] $1"
}

require_env() {
    local name="$1"
    local value="${!name:-}"
    if [[ -z "$value" ]]; then
        die "Required env var not set: $name (check your .env file)"
    fi
}

# =============================================================================
# Auth Helpers
# =============================================================================

# Build forge/cast auth args from CLI flags
# Sets global: AUTH_ARGS
parse_auth_args() {
    AUTH_ARGS=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --private-key|--account)
                AUTH_ARGS="$1 $2"
                shift 2
                ;;
            --ledger|--interactive)
                AUTH_ARGS="$1"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
}

# Build auth args for deploy step (from --deploy-* flags)
get_deploy_auth() {
    if [[ -n "${DEPLOY_KEY:-}" ]]; then
        echo "--private-key $DEPLOY_KEY"
    elif [[ -n "${DEPLOY_ACCOUNT:-}" ]]; then
        echo "--account $DEPLOY_ACCOUNT"
    elif [[ "${DEPLOY_LEDGER:-}" == "true" ]]; then
        echo "--ledger"
    elif [[ "${DEPLOY_INTERACTIVE:-}" == "true" ]]; then
        echo "--interactive"
    fi
}

# Build auth args for execute step (from --execute-* flags)
get_execute_auth() {
    if [[ -n "${EXECUTE_KEY:-}" ]]; then
        echo "--private-key $EXECUTE_KEY"
    elif [[ -n "${EXECUTE_ACCOUNT:-}" ]]; then
        echo "--account $EXECUTE_ACCOUNT"
    elif [[ "${EXECUTE_LEDGER:-}" == "true" ]]; then
        echo "--ledger"
    elif [[ "${EXECUTE_INTERACTIVE:-}" == "true" ]]; then
        echo "--interactive"
    fi
}

# Parse --deploy-* and --execute-* flags into variables
parse_deploy_execute_auth() {
    DEPLOY_KEY=""
    DEPLOY_ACCOUNT=""
    DEPLOY_LEDGER=false
    DEPLOY_INTERACTIVE=false
    EXECUTE_KEY=""
    EXECUTE_ACCOUNT=""
    EXECUTE_LEDGER=false
    EXECUTE_INTERACTIVE=false
    DRY_RUN=false
    SKIP_EXECUTE=false
    VERIFY_CONTRACTS=false
    REMAINING_ARGS=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --deploy-key) DEPLOY_KEY="$2"; shift 2 ;;
            --deploy-account) DEPLOY_ACCOUNT="$2"; shift 2 ;;
            --deploy-ledger) DEPLOY_LEDGER=true; shift ;;
            --deploy-interactive) DEPLOY_INTERACTIVE=true; shift ;;
            --execute-key) EXECUTE_KEY="$2"; shift 2 ;;
            --execute-account) EXECUTE_ACCOUNT="$2"; shift 2 ;;
            --execute-ledger) EXECUTE_LEDGER=true; shift ;;
            --execute-interactive) EXECUTE_INTERACTIVE=true; shift ;;
            --dry-run|-n) DRY_RUN=true; shift ;;
            --skip-execute) SKIP_EXECUTE=true; shift ;;
            --verify|-v) VERIFY_CONTRACTS=true; shift ;;
            *) REMAINING_ARGS+=("$1"); shift ;;
        esac
    done
}

# =============================================================================
# Forge Script Helpers
# =============================================================================

get_chain_id() {
    local rpc="$1"
    cast chain-id --rpc-url "$rpc"
}

parse_action_address() {
    local script_path="$1"
    local chain_id="$2"
    local script_name=$(basename "$script_path")
    local broadcast_file="/app/broadcast/${script_name}/${chain_id}/run-latest.json"

    if [[ ! -f "$broadcast_file" ]]; then
        die "Broadcast file not found: $broadcast_file"
    fi

    local address=$(jq -r '.transactions | map(select(.transactionType == "CREATE")) | last | .contractAddress' "$broadcast_file")

    if [[ -z "$address" || "$address" == "null" ]]; then
        die "Could not parse action address from broadcast file"
    fi

    echo "$address"
}
