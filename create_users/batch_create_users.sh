#!/bin/bash
# =========================================================
# Batch create users with custom group, home directory, and shell
# Format: username:group:password:home:shell
# Example: alice:research:123456:/data/users/alice:/bin/bash
# Usage: sudo bash batch_create_users.sh user_list.txt
# =========================================================

USER_FILE="$1"
LOG_FILE="/var/log/user_batch_create.log"

# --- Root privilege check ---
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root."
    exit 1
fi

# --- Input validation ---
if [ -z "$USER_FILE" ]; then
    echo "Usage: $0 user_list.txt"
    exit 1
fi

if [ ! -f "$USER_FILE" ]; then
    echo "Error: File $USER_FILE does not exist."
    exit 1
fi

echo "=== Batch user creation log $(date) ===" > "$LOG_FILE"
echo "Starting batch user creation..."

FAIL_COUNT=0
SUCCESS_USERS=()

# --- Main loop ---
while IFS=":" read -r username group password homedir shell; do
    # Skip empty or comment lines
    [[ -z "$username" || "$username" =~ ^# ]] && continue

    # Validate mandatory fields
    if [ -z "$group" ] || [ -z "$password" ] || [ -z "$homedir" ]; then
        echo "Skipping invalid line: $username:$group:$password:$homedir:$shell"
        echo "$(date '+%F %T') Invalid line skipped: $username:$group:$password:$homedir:$shell" >> "$LOG_FILE"
        continue
    fi

    # Default shell if empty
    if [ -z "$shell" ]; then
        shell="/bin/bash"
    fi

    echo "Processing user: $username (group: $group, home: $homedir, shell: $shell)"

    # Ensure group exists
    if ! getent group "$group" > /dev/null; then
        echo "Creating group: $group"
        groupadd "$group"
    fi

    # Skip existing users
    if id "$username" &>/dev/null; then
        echo "User $username already exists, skipping."
        echo "$(date '+%F %T') User $username already exists" >> "$LOG_FILE"
        continue
    fi

    # Create user
    useradd -m -d "$homedir" -g "$group" -s "$shell" "$username"
    if [ $? -ne 0 ]; then
        echo "Failed to create user: $username"
        echo "$(date '+%F %T') Failed to create user $username" >> "$LOG_FILE"
        ((FAIL_COUNT++))
        continue
    fi

    # Set password
    echo "$username:$password" | chpasswd
    if [ $? -ne 0 ]; then
        echo "Failed to set password for $username"
        echo "$(date '+%F %T') Failed to set password for $username" >> "$LOG_FILE"
        ((FAIL_COUNT++))
        continue
    fi

    echo "User $username created successfully (group: $group, home: $homedir, shell: $shell)"
    echo "$(date '+%F %T') User $username created successfully, group: $group, home: $homedir, shell: $shell" >> "$LOG_FILE"
    SUCCESS_USERS+=("$username")

done < "$USER_FILE"

# --- Summary report ---
echo
echo "========================================================="
echo "Batch process completed."
echo "Log file: $LOG_FILE"
echo "Users created successfully: ${#SUCCESS_USERS[@]}"
if [ ${#SUCCESS_USERS[@]} -gt 0 ]; then
    printf '%s\n' "${SUCCESS_USERS[@]}" | while read -r u; do
        getent passwd "$u" | awk -F: '{printf "  %-15s home=%-25s shell=%s\n", $1, $6, $7}'
    done
fi
echo "Users failed to create: $FAIL_COUNT"
echo "========================================================="

# Exit code reflects if any failure occurred
if [ $FAIL_COUNT -gt 0 ]; then
    exit 1
else
    exit 0
fi

