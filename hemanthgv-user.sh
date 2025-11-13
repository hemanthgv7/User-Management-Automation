#!/bin/bash
# ============================================
# Script Name: hemanthgv-user.sh
# Purpose: Automatically create users and groups
# Author: Hemanth GV
# ============================================

# Check if an input file is provided
if [ -z "$1" ]; then
  echo "Usage: sudo ./hemanthgv-user.sh users.txt"
  exit 1
fi

INPUT_FILE="$1"
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"

# Create necessary folders and files
sudo mkdir -p /var/secure
sudo touch "$LOG_FILE" "$PASSWORD_FILE"
sudo chmod 600 "$LOG_FILE" "$PASSWORD_FILE"

echo "Starting user creation process..."
echo "-----------------------------------"

# Read the file line by line
while IFS=';' read -r username groups; do

  # Skip comments and empty lines
  if [[ "$username" =~ ^#.*$ || -z "$username" ]]; then
    continue
  fi

  # Remove hidden Windows characters and spaces
  username=$(echo "$username" | tr -d '\r' | xargs)
  groups=$(echo "$groups" | tr -d '\r' | xargs)

  echo "Processing user: $username"

  # Check if user already exists
  if id "$username" &>/dev/null; then
    echo "User $username already exists, skipping." | tee -a "$LOG_FILE"
    continue
  fi

  # Create user with home directory
  sudo useradd -m "$username"
  echo "User $username created." | tee -a "$LOG_FILE"

  # Handle group creation and assignment
  IFS=',' read -ra group_array <<< "$groups"
  for group in "${group_array[@]}"; do
    group=$(echo "$group" | xargs)
    if [ -z "$group" ]; then
      continue
    fi

    # Create group if it doesn't exist
    if ! getent group "$group" >/dev/null; then
      sudo groupadd "$group"
      echo "Created group: $group" | tee -a "$LOG_FILE"
    fi

    # Add user to group
    sudo usermod -aG "$group" "$username"
    echo "Added $username to group $group" | tee -a "$LOG_FILE"
  done

  # Generate random 12-character password
  PASSWORD=$(openssl rand -base64 12)

  # Set password for the user
  echo "$username:$PASSWORD" | sudo chpasswd
  echo "Password set for $username" | tee -a "$LOG_FILE"

  # Save credentials
  echo "$username : $PASSWORD" | sudo tee -a "$PASSWORD_FILE" >/dev/null

done < "$INPUT_FILE"

echo "-----------------------------------"
echo "All users processed successfully!"
echo "Check log: $LOG_FILE"
echo "Check passwords: $PASSWORD_FILE"
