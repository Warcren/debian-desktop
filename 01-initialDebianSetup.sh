#!/bin/bash

## check for sudo/root
if ! [ $(id -u) = 0 ]; then
  echo "This script must run with sudo, try again..."
  exit 1
fi

# Get the username of the user who invoked sudo
if [ "$SUDO_USER" ]; then
  username="$SUDO_USER"
else
  username="$(whoami)"
fi

# Get the home directory of the user
homedir=$(getent passwd "$username" | cut -d: -f6)

# This function runs the 'sudo apt-get install -y nala' command and install nala on the OS
run_nala_install() {
	
    sudo apt update && sudo apt upgrade
    sudo apt-get install -y nala
}

# This function runs the 'sudo nala fetch' command and sends the response '1 2 3 y' when prompted for input
run_nala_fetch() {
    echo "Running 'sudo nala fetch' command..."
    { echo "1 2 3"; echo "y"; } | sudo nala fetch
}

# Define a function to add the code to a file
add_code_to_file() {
  # Define the code to be added
	code='apt() { 
  command nala "$@"
}
sudo() {
  if [ "$1" = "apt" ]; then
    shift
    command sudo nala "$@"
  else
    command sudo "$@"
  fi
}'
  
  file="$1"
  # Check if the code is already present at the end of the file
  if ! tail -n6 "$file" | grep -qF "$code"; then
    # If not, append the code to the file
    echo "$code" >> "$file"
  fi
}

# This function runs the 'nala' command and installs several needed packages:
run_nala_installPackages() {

    sudo nala install -y xz-utils curl nano debconf ufw fail2ban net-tools iptables picom unzip
}

# This function installs NixPackages:
run_nix_install() {
    echo "Running Nix Installation using  determinate.systems/nix installation command..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

}

#This Function activates the nix-daemon script and installs Jellyfin using Nix
run_installnixpack() {
  # Define the commands to be run
  command1=". /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  command2="nix profile install nixpkgs#librewolf"
  command3="nix profile install nixpkgs#conky"
  command4="nix profile install nixpkgs#ulauncher"

  # Run the commands
  eval "$command1"
  eval "$command2"
  eval "$command3"
  eval "$command4"
}
#This function
run_install_lightdm() {
    sudo nala install -y \
	lightdm \
	slick-greeter \
	accountsservice

	sudo systemctl daemon-reload
	sudo systemctl enable lightdm
	sudo dpkg-reconfigure lightdm
	sudo systemctl start lightdm
}

#This function applies a security baseline.
setup_security() {
    # Setup UFW rules
    sudo ufw limit 22/tcp  
    sudo ufw allow 80/tcp  
    sudo ufw allow 443/tcp
    sudo ufw default deny incoming  
    sudo ufw default allow outgoing
    sudo ufw enable

    # Harden /etc/sysctl.conf
    sudo sysctl kernel.modules_disabled=1
    sudo sysctl -a
    sudo sysctl -A
    sudo sysctl mib
    sudo sysctl net.ipv4.conf.all.rp_filter
    sudo sysctl -a --pattern 'net.ipv4.conf.(eth|wlan)0.arp'

    # PREVENT IP SPOOFS
    cat <<EOF > /etc/host.conf
order bind,hosts
multi on
EOF

    # Enable fail2ban
    sudo cp jail.local /etc/fail2ban/
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban

    echo "listening ports"
    sudo netstat -tunlp 
}

run_xfce_install() {
cat ./xsessionrc >> /home/$SUDO_USER/.xsessionrc
chown $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.xsessionrc

    sudo nala install  -y \
    libxfce4ui-utils \
    thunar \
    xfce4-appfinder \
    xfce4-panel \
    xfce4-panel-profiles \
    xfce4-pulseaudio-plugin \
    xfce4-whiskermenu-plugin \
    xfce4-session \
    xfce4-settings \
    xfce4-terminal \
    xfconf \
    xfdesktop4 \
    xfwm4 \
    adwaita-qt \
    qt5ct \
    network-manager-openvpn network-manager-gnome \
    network-manager-openvpn-gnome
}

run_xfce_dock_install() {

#Can we uninstall some packages after Install?
sudo nala install -y \
	wget \
	xorg-dev \
	libglib2.0-cil-dev \
	golang-gir-gio-2.0-dev \
	libgtk-3-dev \
	libwnck-3-dev \
	libxfce4ui-2-dev \
	libxfce4panel-2.0-dev \
	intltool \
	bzip2 \
	build-essential \
	xfce4-dev-tools
	
	#wget https://archive.xfce.org/src/panel-plugins/xfce4-docklike-plugin/0.4/xfce4-docklike-plugin-0.4.1.tar.bz2
	#tar -xvjf xfce4-docklike-plugin-0.4.1.tar.bz2 && cd xfce4-docklike-plugin-0.4.1
	#./configure
	#make
	#sudo make install
	#cd ..
	
	git clone https://gitlab.xfce.org/panel-plugins/xfce4-docklike-plugin.git && cd xfce4-docklike-plugin
	./autogen.sh
	make
	sudo make install

	
	
	cd /usr/share/xfce4/panel/plugins/
	sudo ln -s /usr/local/share/xfce4/panel/plugins/docklike.desktop docklike.desktop
	cd /home/$SUDO_USER/debian-desktop/
}

run_custom_desktop() {

	git clone https://github.com/Warcren/qogir-theme.git
	./qogir-theme/install.sh
	./qogir-theme/install.sh --tweaks round

	git clone https://github.com/Warcren/qogir-icon-theme.git
	mkdir -p "$homedir/.icons"
	./qogir-icon-theme/install.sh -d "$homedir/.icons"

	#fonts.zip
	unzip fonts.zip
	mv fonts ~/.local/share/

	#Setup Ulauncher
	unzip ulauncher-theme-goxir-dark.zip
	mkdir -p "$homedir/.config/ulauncher/user-themes/"
	mv goxir-dark "$homedir/ulauncher/user-themes/"

	#Move Menu Config
	unzip whisker-menu.gtk.css.dark
	mv gtk.css "$homedir/gtk-3.0/"
	xfce4-panel -r

	#Install Conky
	unzip conky.zip
	mv conky "$homedir/.config/"

	#Install Picom
	unzip picom.zip
	mkdir -p "$homedir/.config/picom"
	mv picom/picom.desktop "$homedir/.config/autostart"
	mv picom/picom.conf "$homedir/.config/picom"
}

# Main script
echo "Starting script..."

#Install Nala and Fetch best mirrors
run_nala_install
run_nala_fetch

# Add the code to both files
add_code_to_file "$homedir/.bashrc"
add_code_to_file /root/.bashrc

#Install Additional Packages
run_nala_installPackages

#Installs Nix Package Manager
run_nix_install

#Installs Nix Packages
run_installnixpack

#Install LightDm
run_install_lightdm

#Hardens Server
setup_security

#Install Minimal XFCE Desktop Manager
run_xfce_install

#Install 
run_xfce_dock_install

#Custom Desktop
#run_custom_desktop

echo "Script finished."
