#!/bin/bash


# Get the username of the user who invoked sudo
if [ "$SUDO_USER" ]; then
  username="$SUDO_USER"
else
  username="$(whoami)"
fi

# Get the home directory of the user
homedir=$(getent passwd "$username" | cut -d: -f6)

run_bash_install() {
	cd "$homedir/"
	git clone https://github.com/Warcren/mybash.git
 	cd mybash
  	mv setup.sh "$homedir/"
   	mv starship.toml "$homedir/"
    	cd "$homedir/"
  	chmod +x setup.sh
   	sudo ./setup.sh
    	cd "$homedir/debian-desktop"
}

#Setup Custom Bash
run_bash_install
