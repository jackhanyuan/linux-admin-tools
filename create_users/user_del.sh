#!/bin/bash
# ===============================================
# Script Name: user_del.sh
# Description: Delete a specified user, optionally with home directory
# Usage: sudo ./user_del.sh <username> [--remove-home]
# Example: sudo ./user_del.sh username --remove-home
# ===============================================

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

# Check arguments
if [ -z "$1" ]; then
    echo "Usage: $0 <username> [--remove-home]"
    exit 1
fi

USERNAME=$1
REMOVE_HOME=false

if [ "$2" == "--remove-home" ]; then
    REMOVE_HOME=true
fi

# Check if user exists
if ! id "$USERNAME" &>/dev/null; then
    echo "User $USERNAME does not exist."
    exit 1
fi

# Confirm deletion
if [ "$REMOVE_HOME" = true ]; then
    read -p "Delete user $USERNAME and its home directory? (y/N): " confirm
else
    read -p "Delete user $USERNAME but keep home directory? (y/N): " confirm
fi

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Operation cancelled."
    exit 0
fi

# Perform deletion
if [ "$REMOVE_HOME" = true ]; then
    userdel -r "$USERNAME"
else
    userdel "$USERNAME"
fi

if [ $? -eq 0 ]; then
    echo "User $USERNAME deleted successfully."
else
    echo "Failed to delete user $USERNAME."
fi

