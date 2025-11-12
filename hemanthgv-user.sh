#!/bin/bash
# This script creates new users and adds them to groups automatically.
# Each line in the input file should look like this:
# username;group1,group2
# Example:
# light; sudo,dev,www-data

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)."
  exit 1
fi

# Check if an input file is given
if [ -z "$1" ]; then
  echo "Usage: sudo ./create_users.sh users.txt"
  exit 1
fi

INPUT_FILE="$1"
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"

# Make sure the log and password files exist and are protected
mkdir -p /var/secure
> "$LOG_FILE"
> "$PASSWORD_FILE"
chmod 600 "$LOG_FILE" "$PASSWORD_FILE"

# Function to log messages with time
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to generate a random 12-character password
generate_password() {
  tr -dc 'A-Za-z0-9' </dev/urandom | head -c 12
}

# Read the input file line by line
while IFS= read -r line; do
  # Skip empty lines and comments
  [[ -z "$line" || "$line" == \#* ]] && continue

  # Split line into username and groups
  username=$(echo "$line" | cut -d';' -f1 | xargs)
  groups=$(echo "$line" | cut -d';' -f2 | tr -d ' ')

  # Skip if username is empty
  if [ -z "$username" ]; then
    log "Skipping line with empty username."
    continue
  fi

  # Create groups if they don’t exist
  IFS=',' read -r -a group_list <<< "$groups"
  for group in "${group_list[@]}"; do
    if [ -n "$group" ] && ! getent group "$group" >/dev/null; then
      groupadd "$group"
      log "Created group: $group"
    fi
  done

  # Create the user if not exists
  if id "$username" &>/dev/null; then
    log "User $username already exists."
  else
    useradd -m -s /bin/bash "$username"
    log "Created user: $username"
  fi

  # Add user to groups
  for group in "${group_list[@]}"; do
    if [ -n "$group" ]; then
      usermod -aG "$group" "$username"
      log "Added $username to group $group"
    fi
  done

  # Generate password and set it
  password=$(generate_password)
  echo "$username:$password" | chpasswd
  echo "$username:$password" >> "$PASSWORD_FILE"
  log "Set password for user: $username"

done < "$INPUT_FILE"

echo "All users processed successfully! Check $LOG_FILE and $PASSWORD_FILE for details."
