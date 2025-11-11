#!/bin/bash
# ===============================================
# Script Name: gen_user_keys.sh
# Description: Generate SSH keypairs for users (from file or single user)
# Usage:
#   sudo ./gen_user_keys.sh user_list.txt [--force]
#   sudo ./gen_user_keys.sh username [--force]
# ===============================================

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYS_DIR="${SCRIPT_DIR}/keys"
mkdir -p "$KEYS_DIR"
chmod 700 "$KEYS_DIR"

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

if [ $# -lt 1 ]; then
    echo "Usage: $0 <user_list.txt | username> [--force]"
    exit 1
fi

INPUT=$1
FORCE=false
[ "${2:-}" == "--force" ] && FORCE=true

# --- Counters for summary ---
export_created_count=0
export_overwritten_count=0
skipped_auth_count=0
forced_regen_count=0
export_skip_exist_count=0
skipped_user_missing_count=0

process_user() {
    local USERNAME=$1
    local HOME_DIR
    HOME_DIR=$(getent passwd "$USERNAME" | cut -d: -f6)

    if [ -z "$HOME_DIR" ] || [ ! -d "$HOME_DIR" ]; then
        echo "SKIP: user $USERNAME not found or home directory missing."
        ((skipped_user_missing_count++))
        return
    fi

    local SSH_DIR="${HOME_DIR}/.ssh"
    local AUTH_KEYS="${SSH_DIR}/authorized_keys"
    local PRIV_KEY="${SSH_DIR}/id_ed25519"
    local PUB_KEY="${SSH_DIR}/id_ed25519.pub"
    local DEST_KEY_FILE="${KEYS_DIR}/${USERNAME}"

    # ensure ~/.ssh exists (do not change permissions explicitly)
    if [ ! -d "$SSH_DIR" ]; then
        runuser -l "$USERNAME" -c "mkdir -p ~/.ssh"
    fi

    # if authorized_keys already exists and has content -> skip unless --force
    if [ -s "$AUTH_KEYS" ] && [ "$FORCE" = false ]; then
        echo "SKIP: $USERNAME already has authorized_keys (use --force to regenerate)."
        ((skipped_auth_count++))
        return
    fi

    if [ "$FORCE" = true ]; then
        echo "FORCE: regenerating SSH keypair for $USERNAME..."
        rm -f "$PRIV_KEY" "$PUB_KEY" "$AUTH_KEYS"
        ((forced_regen_count++))
    else
        echo "Processing $USERNAME..."
    fi

    # If keypair exists and not forcing, reuse; otherwise generate
    if [ -f "$PRIV_KEY" ] && [ -f "$PUB_KEY" ] && [ "$FORCE" = false ]; then
        echo "INFO: existing keypair found for $USERNAME, reusing."
    else
        runuser -l "$USERNAME" -c "ssh-keygen -t ed25519 -f '${PRIV_KEY}' -N '' -q"
    fi

    # append public key to authorized_keys (file may be new or empty now)
    runuser -l "$USERNAME" -c "cat '${PUB_KEY}' >> '${AUTH_KEYS}'"

    # export private key to keys/ folder
    if [ -f "$DEST_KEY_FILE" ]; then
        if [ "$FORCE" = true ]; then
            cp -f "$PRIV_KEY" "$DEST_KEY_FILE"
            chmod 600 "$DEST_KEY_FILE"
            chown root:root "$DEST_KEY_FILE"
            echo "OVERWRITE: private key exported to $DEST_KEY_FILE (forced)."
            ((export_overwritten_count++))
        else
            read -p "keys/${USERNAME} exists. Overwrite? (y/N): " ans
            if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
                cp -f "$PRIV_KEY" "$DEST_KEY_FILE"
                chmod 600 "$DEST_KEY_FILE"
                chown root:root "$DEST_KEY_FILE"
                echo "OVERWRITE: private key exported to $DEST_KEY_FILE."
                ((export_overwritten_count++))
            else
                echo "SKIP: keys/${USERNAME} exists, not overwritten."
                ((export_skip_exist_count++))
            fi
        fi
    else
        cp "$PRIV_KEY" "$DEST_KEY_FILE"
        chmod 600 "$DEST_KEY_FILE"
        chown root:root "$DEST_KEY_FILE"
        echo "OK: private key saved to $DEST_KEY_FILE"
        ((export_created_count++))
    fi
}

# --- Main entry ---
if [ -f "$INPUT" ]; then
    echo "Processing user list: $INPUT"
    while IFS= read -r line || [ -n "$line" ]; do
        [[ -z "$line" || "${line:0:1}" == "#" ]] && continue
        USERNAME=$(echo "$line" | cut -d: -f1)
        process_user "$USERNAME"
    done < "$INPUT"
else
    process_user "$INPUT"
fi

echo "---------------------------------------------"
echo "SUMMARY:"
echo "  Export created:     $export_created_count"
echo "  Export overwritten: $export_overwritten_count"
echo "  Forced regenerations: $forced_regen_count"
echo "  Skipped (auth_keys exists): $skipped_auth_count"
echo "  Skipped (export exists, no overwrite): $export_skip_exist_count"
echo "  Skipped (user/home missing): $skipped_user_missing_count"
echo "DONE."

