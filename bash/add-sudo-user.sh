#!/bin/bash
#This option causes the bash shell to treat unset variables as an error and exit.
set -u
#author: Raffye.Memon (raffye.memon@technologywizz.com)
#date: 18-Sep-2024
#description: Add user + add to sudo + add to visudo (with deferred execution)

# Function to create the user
create_user() {
    sudo useradd -m -s /bin/bash "$username"
    echo "$username:$password" | sudo chpasswd
    if [ $? -eq 0 ]; then
        echo "User $username created successfully."
    else
        echo "Failed to create user $username."
        return 1
    fi
}

# Function to add the user to the sudo group
add_to_sudo_group() {
    sudo usermod -aG sudo "$username"
    if [ $? -eq 0 ]; then
        echo "User $username added to the sudo group."
    else
        echo "Failed to add $username to the sudo group."
        return 1
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

# Function to add user to visudo
add_to_visudo() {
    echo "$username ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/$username > /dev/null
    if [ $? -eq 0 ]; then
        echo "User $username added to visudo with NOPASSWD privileges."
    else
        echo "Failed to add $username to visudo."
        return 1
    fi
}

# Main script execution starts here
echo "Please provide the following information. No changes will be made until all inputs are collected."

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
    echo "Passwords do not match. Aborting."
    exit 1
fi

# Prompt for visudo addition
read -p "Do you want to add $username to visudo with NOPASSWD privileges? (y/n): " add_to_visudo_choice

# Prompt for a public key (optional)
read -p "Enter the public key (or press Enter to skip): " public_key

# Review the collected information
echo -e "\nPlease review the following information:"
echo "Username: $username"
echo "Password: [hidden]"
echo "Add to visudo: $add_to_visudo_choice"
echo "Public key: ${public_key:-None}"

# Confirm execution
read -p "Do you want to proceed with these changes? (y/n): " confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    # Execute the changes
    if create_user && add_to_sudo_group; then
        if [[ "$add_to_visudo_choice" =~ ^[Yy]$ ]]; then
            add_to_visudo || exit 1
        fi
        add_public_key
        echo "All operations completed successfully."
    else
        echo "An error occurred. Some operations may not have completed."
        exit 1
    fi
else
    echo "Operation cancelled. No changes were made."
    exit 0
fi