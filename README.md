# README 

## What this script does

This script helps you create many user accounts automatically. It also creates groups, adds users to groups, and sets random passwords.

## How to use it

1. Save your usernames and groups in a file (for example: `users.txt`).

Example `users.txt`:

```
# Comment lines start with #
light; sudo,dev,www-data
siyoni; sudo
manoj; dev,www-data
```

2. Run the script as root:

```
sudo ./create_users.sh users.txt
```

3. It will:

   * Create users and groups
   * Add users to groups
   * Create home directories
   * Set random passwords
   * Save passwords in `/var/secure/user_passwords.txt`
   * Write logs in `/var/log/user_management.log`

## Security note

* Only the root user can read the password and log files.
* Do not share `/var/secure/user_passwords.txt`.
* You can make users change their password later using:

  ```bash
  sudo passwd -e username
  ```
