#!/bin/bash
#This option causes the bash shell to treat unset variables as an error and exit.
set -u
#author: Raffye.Memon (raffye.memon@technologywizz.com)
#date: 03.03.23
#description: Add user + add to sudo

# Function to create the user
create_user() {
    sudo useradd -m -s /bin/bash "$username"
    echo "$username:$password" | sudo chpasswd
    if [ $? -eq 0 ]; then
        echo "User $username created successfully."
    else
        echo "Failed to create user $username."
        exit 1
    fi
}

# Function to add the user to the sudo group
add_to_sudo_group() {
    sudo usermod -aG sudo "$username"
    if [ $? -eq 0 ]; then
        echo "User $username added to the sudo group."
    else
        echo "Failed to add $username to the sudo group."
        exit 1
    fi
}

# Function to add a public key
add_public_key() {
    if [ -n "$public_key" ]; then
        sudo -u "$username" mkdir -p "/home/$username/.ssh"
        echo "$public_key" | sudo -u "$username" tee "/home/$username/.ssh/authorized_keys" >/dev/null
        echo "Public key added to user $username's authorized_keys file."
    fi
}

# Prompt for the username
read -p "Enter the username: " username

# Check if the user already exists
if id "$username" &>/dev/null; then
    echo "User $username already exists."
    exit 1
fi

# Prompt for the password (and confirm it)
read -s -p "Enter the password: " password
echo
read -s -p "Confirm the password: " password_confirm
echo

# Check if the passwords match
if [ "$password" != "$password_confirm" ]; then
    echo "Passwords do not match. User not created."
    exit 1
fi

# Create the user with the provided username, password, and set the shell to /bin/bash
create_user

# Add the user to the sudo group
add_to_sudo_group

# Prompt for a public key (optional)
read -p "Enter the public key (or press Enter to skip): " public_key

# Add the public key (if provided)
add_public_key
