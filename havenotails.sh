#!/bin/bash

# Function to print messages in blue
echo_blue() {
  echo -e "\033[1;34m$1\033[0m"
}

# Function to print error messages in red
echo_red() {
  echo -e "\033[0;31m$1\033[0m"
}

# Function to print success messages in green
echo_green() {
  echo -e "\033[1;32m$1\033[0m"
}

# Function to show a progress bar
show_progress() {
    echo -ne '###                     (20%)\r'
    sleep 1
    echo -ne '#########                (40%)\r'
    sleep 1
    echo -ne '##############           (60%)\r'
    sleep 1
    echo -ne '###################      (80%)\r'
    sleep 1
    echo -ne '#########################(100%)\r'
    echo -ne '\n'
}

# Step 1: Ensure Tor is running
echo_blue "Step 1: Ensuring Tor is running..."
if ! sudo systemctl is-active --quiet tor; then
    echo_red "Tor is not running. Starting Tor..."
    sudo systemctl start tor
    sleep 5
    if ! sudo systemctl is-active --quiet tor; then
        echo_red "Failed to start Tor. Please troubleshoot your Tor setup."
        exit 1
    fi
fi
echo_green "Tor is running."

# Step 2: Check if Tor proxy is reachable
echo_blue "Step 2: Checking if the Tor proxy is reachable..."
if ! curl --socks5-hostname 127.0.0.1:9050 https://check.torproject.org/ > /dev/null 2>&1; then
    echo_red "Tor proxy is unreachable. Restarting Tor and retrying..."
    sudo systemctl restart tor
    sleep 5
    if ! curl --socks5-hostname 127.0.0.1:9050 https://check.torproject.org/ > /dev/null 2>&1; then
        echo_red "Tor proxy is still unreachable. Please troubleshoot your Tor setup."
        exit 1
    fi
fi
echo_green "Tor proxy is reachable."

# Step 3: Clear apt cache to avoid hash sum mismatch issues
echo_blue "Step 3: Clearing apt cache to avoid potential hash sum mismatch issues..."
sudo apt clean
sudo rm -rf /var/lib/apt/lists/*
sudo apt update || { echo_red "Failed to update apt package lists."; exit 1; }
echo_green "APT cache cleaned and updated successfully."

# Set up variables
user_url="https://github.com/retoaccess1/haveno-reto/releases/latest/download/haveno_amd64_deb-latest.zip"
expected_fingerprint="FAA24D878B8D36C90120A897CA02DAC12DAE2D0F"
binary_filename=$(basename "$user_url")
signature_filename="${binary_filename}.sig"
install_dir="/home/amnesia/Persistent/haveno/Install"

# Step 4: Installing dependencies
echo_blue "Step 4: Installing dependencies like curl and unzip to make sure we can download and extract files."
show_progress
sudo apt update && sudo apt install -y curl unzip
if [ $? -ne 0 ]; then
  echo_red "Error: Failed to install dependencies."
  exit 1
fi
echo_green "Dependencies installed successfully!"

# Step 5: Setting up installation directories
echo_blue "Step 5: Setting up installation directories to store Haveno files persistently."
show_progress
mkdir -p "${install_dir}" || { echo_red "Error: Failed to create directory ${install_dir}"; exit 1; }
echo_green "Directories created!"

# Step 6: Downloading the Haveno binary
echo_blue "Step 6: Downloading the Haveno binary from the official URL. This ensures you have the latest version!"
show_progress
curl --socks5-hostname 127.0.0.1:9050 --progress-bar -L -o "${binary_filename}" "${user_url}" || { echo_red "Error: Failed to download Haveno binary."; exit 1; }
echo_green "Haveno binary downloaded successfully!"

# Step 7: Downloading the PGP key and signature
echo_blue "Step 7: Downloading the PGP key and signature to verify the authenticity of the Haveno binary."
show_progress
curl --socks5-hostname 127.0.0.1:9050 --progress-bar -L -o "${signature_filename}" "${user_url}.sig" || { echo_red "Error: Failed to download Haveno signature."; exit 1; }
curl --progress-bar -O https://haveno-reto.com/reto_public.asc || { echo_red "Error: Failed to download PGP key."; exit 1; }
echo_green "PGP key and signature downloaded successfully!"

# Step 8: Importing the PGP key
echo_blue "Step 8: Importing the PGP key to verify the Haveno binary."
show_progress
gpg --import reto_public.asc || { echo_red "Error: Failed to import PGP key."; exit 1; }
echo_green "PGP key imported successfully!"

# Step 9: Verifying the Haveno binary
echo_blue "Step 9: Verifying the Haveno binary to ensure it’s authentic and secure."
show_progress
gpg --verify "${signature_filename}" "${binary_filename}"
if [ $? -ne 0 ]; then
  echo_red "Error: Binary verification failed! The file may have been tampered with."
  exit 1
fi
echo_green "Haveno binary verified successfully!"

# Step 10: Unzipping and installing the binary
echo_blue "Step 10: Unzipping and installing Haveno. This makes it ready to run on your system."
show_progress
unzip "${binary_filename}" -d "${install_dir}" || { echo_red "Error: Failed to unzip Haveno binary."; exit 1; }
echo_green "Haveno installed successfully!"

# Final message
echo_green "Installation completed! You can now run Haveno from your persistent storage."
