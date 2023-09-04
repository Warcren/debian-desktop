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

# This function runs the 'nala' command and installs several needed packages:
run_nala_installPackages() {

	sudo nala install -y \
	xz-utils \
	curl \
	nano \
	debconf \
	ufw \
	fail2ban \
	net-tools \
	iptables \
	picom \
	unzip \
	dbus-x11 \
	neofetch \
	htop \
	psmisc \
	jq \
	sed \
	gawk \
	iw \
	xbindkeys \
	rofi
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
    sudo bash -c 'echo -e "order bind,hosts\nmulti on" > /etc/host.conf'

    # Enable fail2ban
    sudo cp jail.local /etc/fail2ban/
    sudo touch /var/log/auth.log
    echo "logpath = /var/log/auth.log" | sudo tee -a /etc/fail2ban/jail.d/defaults-debian.conf

    sudo systemctl enable fail2ban
    sudo systemctl daemon-reload
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
    thunar-volman \
    thunar-archive-plugin \
    xfce4-panel \
    xfce4-panel-profiles \
    xfce4-pulseaudio-plugin \
    xfce4-whiskermenu-plugin \
    xfce4-session \
    xfce4-settings \
    kitty \
    xfconf \
    xfdesktop4 \
    xfwm4 \
    adwaita-qt \
    qt5ct \
    network-manager-openvpn network-manager-gnome \
    network-manager-openvpn-gnome \
    sassc \
    ristretto \
    mpv \
    mupdf \
    trash-cli
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
	
	git clone https://gitlab.xfce.org/panel-plugins/xfce4-docklike-plugin.git && cd xfce4-docklike-plugin
	./autogen.sh
	make
	sudo make install

		
	cd /usr/share/xfce4/panel/plugins/
	sudo ln -s /usr/local/share/xfce4/panel/plugins/docklike.desktop docklike.desktop
	cd /home/$SUDO_USER/debian-desktop/
 	sudo mkdir -p /usr/lib/xfce4/panel-plugins/
	sudo mkdir -p /usr/share/xfce4/panel-plugins/ 
	sudo cp /usr/local/lib/xfce4/panel/plugins/libdocklike.la /usr/share/xfce4/panel-plugins/
	sudo cp /usr/local/lib/xfce4/panel/plugins/libdocklike.so /usr/share/xfce4/panel-plugins/
	sudo cp /usr/local/lib/xfce4/panel/plugins/libdocklike.la /usr/lib/xfce4/panel-plugins/
	sudo cp /usr/local/lib/xfce4/panel/plugins/libdocklike.so /usr/lib/xfce4/panel-plugins/
}

run_bash_install() {
	cd "$homedir/"
	git clone https://github.com/Warcren/mybash.git
 	cd mybash
  	chmod +x setup.sh
   	sudo ./setup.sh
    	cd "$homedir/debian-desktop"
}

# Main script
echo "Starting script..."

#Install Nala and Fetch best mirrors
run_nala_install
run_nala_fetch

#Install Additional Packages
run_nala_installPackages

#Install LightDm
run_install_lightdm

#Hardens Server
setup_security

#Install Minimal XFCE Desktop Manager
run_xfce_install

#Install 
run_xfce_dock_install

#Setup Custom Bash
#run_bash_install

echo "Script finished."

