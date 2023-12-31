#!/bin/bash

##Run This Script after login in at least once to the new Desktop##

# Get the username of the user who invoked sudo
if [ "$SUDO_USER" ]; then
  username="$SUDO_USER"
else
  username="$(whoami)"
fi

# Get the home directory of the user
homedir=$(getent passwd "$username" | cut -d: -f6)


#This Function activates Installs Nix Package Manager and basic apps
run_installnix() {

  #Install Nix Package Manager 
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

  # Define the commands to be run
  command1=". /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  command2="nix profile install nixpkgs#librewolf"
  command3="nix profile install nixpkgs#conky"
  command4="nix profile install nixpkgs#gnome.gedit"
  command5="nix profile install nixpkgs#mullvad-browser"
  # Run the commands
  eval "$command1"
  eval "$command2"
  eval "$command3"
  eval "$command4"
  eval "$command5"
}

#Installs Nix Package Manager
run_installnix
