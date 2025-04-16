cat install_mina.sh 
#!/bin/bash

set -e

# FOR TESTING PURPOSES ONLY
# MAKE SURE ALL SECRETS ARE LOADED THROUGH SECURE ENV VARIABLES

# ---[ 1. Set up environment variables ]---
export USER=$(whoami)
export MINA_HOME="/home/$USER"
export DEBIAN_FRONTEND=noninteractive
export GIT_LFS_SKIP_SMUDGE=1  # Skip LFS files globally

# ---[ 2. Configure Nix properly ]---
# Create or append to ~/.config/nix/nix.conf
mkdir -p ~/.config/nix
{
  echo "experimental-features = nix-command flakes"
  echo "download-buffer-size = 104857600"  # 100MB buffer
} >> ~/.config/nix/nix.conf

# Export NIX_CONFIG for current session
export NIX_CONFIG="
experimental-features = nix-command flakes
download-buffer-size = 104857600
"


# ---[ 3. Ensure ownership of necessary directories ]---
mkdir -p /nix
sudo chown -R $USER /nix
sudo chown -R $USER:$USER $MINA_HOME

# ---[ 4. Ensure Nix is available in the current shell ]---
. "$HOME/.nix-profile/etc/profile.d/nix.sh"
nix store info

# ---[ 5. Change to MINA_HOME directory ]---
cd $MINA_HOME

# ---[ 6. Clone Mina repository if not already present ]---
if [ ! -d "$MINA_HOME/mina" ]; then
  echo "Cloning Mina repository (without LFS files)..."
  GIT_LFS_SKIP_SMUDGE=1 git clone --recurse-submodules --jobs=8 git@github.com:MinaProtocol/mina.git
fi

# ---[ 7. Verify Mina repository ]---
if [ ! -d "$MINA_HOME/mina" ]; then
  echo "Mina repository not found in $MINA_HOME/mina"
  exit 1
fi

cd "$MINA_HOME/mina"
echo "Current directory: $(pwd)"

# ---[ 8. Checkout version and update submodules ]---
git reset --hard
git clean -xfd
git checkout tags/3.1.0
git submodule sync --recursive
git submodule update --init --force --recursive --jobs=8

# ---[ 9. Disable LFS completely ]---
git lfs uninstall --local
git config --local lfs.fetchexclude "*"

# ---[ 10. Build Mina with proper submodule handling ]---
./nix/pin.sh
nix build "git+file://$PWD?submodules=1"#mina

# ---[ 11. Install Mina binary ]---
sudo cp result/bin/mina /usr/local/bin
sudo chmod +x /usr/local/bin/mina

# ---[ 12. Cleanup ]---
# rm -rf result

echo "Mina installed successfully at /usr/local/bin/mina"