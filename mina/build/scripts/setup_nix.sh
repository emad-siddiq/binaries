# Single user installation 
# https://nixos.org/download/#nix-install-linux

sudo apt-get update && sudo apt-get install -y \
  sudo passwd curl git bash ca-certificates gnupg lsb-release \
  build-essential pkg-config vim sqlite3 libsqlite3-dev
  
sh <(curl -L https://nixos.org/nix/install) --no-daemon
. /home/emad/.nix-profile/etc/profile.d/nix.sh