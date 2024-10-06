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

# Progress bar function using sleep for simplicity
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

# Set up variables
user_url="https://github.com/retoaccess1/haveno-reto/releases/latest/download/haveno_amd64_deb-latest.zip"
expected_fingerprint="FAA24D878B8D36C90120A897CA02DAC12DAE2D0F"
binary_filename=$(basename "$user_url")
signature_filename="${binary_filename}.sig"
install_dir="/home/amnesia/Persistent/haveno/Install"

# Install dependencies
echo_blue "Step 1: Installing dependencies like curl and unzip to make sure we can download and extract files."
show_progress
sudo apt update && sudo apt install -y curl unzip
if [ $? -ne 0 ]; then
  echo_red "Error: Failed to install dependencies."
  exit 1
fi
echo_green "Dependencies installed successfully!"

# Create directories
echo_blue "Step 2: Setting up installation directories to store Haveno files persistently."
show_progress
mkdir -p "${install_dir}" || { echo_red "Error: Failed to create directory ${install_dir}"; exit 1; }
echo_green "Directories created!"

# Download the Haveno binary
echo_blue "Step 3: Downloading the Haveno binary from the official URL. This ensures you have the latest version!"
show_progress
curl --progress-bar -L -o "${binary_filename}" "${user_url}" || { echo_red "Error: Failed to download Haveno binary."; exit 1; }
echo_green "Haveno binary downloaded successfully!"

# Download the PGP key and signature for verification
echo_blue "Step 4: Downloading the PGP key and signature to verify the authenticity of the Haveno binary. This ensures it hasn’t been tampered with!"
show_progress
curl --progress-bar -L -o "${signature_filename}" "${user_url}.sig" || { echo_red "Error: Failed to download Haveno signature."; exit 1; }
curl --progress-bar -O https://haveno-reto.com/reto_public.asc || { echo_red "Error: Failed to download PGP key."; exit 1; }

# Import the PGP key
echo_blue "Step 5: Importing the PGP key into your system to verify the Haveno binary."
show_progress
gpg --import reto_public.asc || { echo_red "Error: Failed to import PGP key."; exit 1; }
echo_green "PGP key imported successfully!"

# Verify the Haveno binary
echo_blue "Step 6: Verifying the Haveno binary to ensure it’s authentic and secure."
show_progress
gpg --verify "${signature_filename}" "${binary_filename}"
if [ $? -ne 0 ]; then
  echo_red "Error: Binary verification failed! The file may have been tampered with."
  exit 1
fi
echo_green "Haveno binary verified successfully!"

# Unzip and install the binary
echo_blue "Step 7: Unzipping and installing Haveno. This makes it ready to run on your system."
show_progress
unzip "${binary_filename}" -d "${install_dir}" || { echo_red "Error: Failed to unzip Haveno binary."; exit 1; }
echo_green "Haveno installed successfully!"

# Final message
echo_green "Installation completed! You can now run Haveno from your persistent storage."
