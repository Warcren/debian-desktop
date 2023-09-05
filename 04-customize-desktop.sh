#!/usr/bin/env bash

# Get the username of the user who invoked sudo
if [ "$SUDO_USER" ]; then
  username="$SUDO_USER"
else
  username="$(whoami)"
fi

# Get the home directory of the user
homedir=$(getent passwd "$username" | cut -d: -f6)

run_custom_desktop() {

	git clone https://github.com/Warcren/qogir-theme.git
	sudo ./qogir-theme/install.sh
	sudo ./qogir-theme/install.sh --tweaks round

	git clone https://github.com/Warcren/qogir-icon-theme.git
	mkdir -p "$homedir/.icons"
	sudo ./qogir-icon-theme/install.sh -d "$homedir/.icons"

	#Move Font Files
	unzip fonts.zip
	sudo mv fonts "$homedir/.local/share/"

	#Move Menu Config
	unzip whisker-menu.gtk.css.dark
	mkdir -p "$homedir/.config/gtk-3.0/"
	mv gtk.css "$homedir/.config/gtk-3.0/"
	xfce4-panel -r

	#Move Conky Configuration files
	unzip conky.zip
	mv conky "$homedir/.config/"

	#Move Picom configuration files
	unzip picom.zip
	mkdir -p "$homedir/.config/picom"
	mv picom/picom.desktop "$homedir/.config/autostart"
	mv picom/picom.conf "$homedir/.config/picom"
	
	#Move LightDm Configuration Files and Wallpaper
	unzip wallpaper.zip
	sudo mv debian-darkstone.png /usr/share/backgrounds/xfce/
	sudo mv main_wallpaper.jpg /usr/share/backgrounds/xfce/
	sudo mv gandalf_cli_wallpaper.jpg /usr/share/backgrounds/xfce/
	sudo mv lightdm_wallpaper.jpg /usr/share/backgrounds/xfce/
	sudo mv -f lightdm.conf /etc/lightdm/
	sudo mv -f slick-greeter.conf /etc/lightdm/
	sudo mv debian-logo-wallpaper.png /etc/lightdm/
	sudo mv debianlogo.png /etc/lightdm/
}

run_conf_rofi() {

	unzip rofi.zip
	mkdir -p "$homedir/.config/rofi"
	mv config.rasi "$homedir/.config/rofi/"

	xbindkeys --defaults > "$homedir/.xbindkeysrc"
	echo '"rofi -show drun"
  Control + space' >> "$homedir/.xbindkeysrc"
	echo "xbindkeys &" >> "$homedir/.xinitrc"
	xbindkeys
}

run_conf_picom() {

  # Define the picom service.
  picom_code='[Unit]
				Description=Picom App Launcher
				After=network.target

				[Service]
				User=leo
				Group=leo
				UMask=002

				Environment="DISPLAY=:0"

				Type=simple
				ExecStart=/usr/bin/picom
				Restart=on-failure
				RestartSec=5
				TimeoutStopSec=20

				[Install]
				WantedBy=multi-user.target'

  #Create Service File if it does not exist
  sudo touch /etc/systemd/system/picom.service
  # Create the service file
  echo "$picom_code" | sudo tee /etc/systemd/system/picom.service > /dev/null
  # Reload the systemd daemon to recognize the new service
  sudo systemctl daemon-reload
  # Enable the service to start automatically at boot
  sudo systemctl enable picom.service
  # Start the service
  sudo systemctl start picom.service
}

run_conf_conky() {


  # Define the Conky service.
  conky_code='[Unit]
				Description=Conky service
				After=network-online.target

				[Service]
				User=leo
				Group=leo
				UMask=002

				Type=simple
				ExecStart=/home/leo/.config/conky/Regulus/start.sh
				Restart=on-failure
				RestartSec=5
				TimeoutStopSec=20

				[Install]
				WantedBy=multi-user.target'

  #Make Conky executable
  chmod +x "$homedir/.config/conky/Regulus/start.sh"
  chmod +x "$homedir/.config/conky/Regulus/scripts/weather.sh"
  #Create Service File if it does not exist
  sudo touch /etc/systemd/system/conky.service
  # Create the service file
  echo "$conky_code" | sudo tee /etc/systemd/system/conky.service > /dev/null
  # Reload the systemd daemon to recognize the new service
  sudo systemctl daemon-reload
  # Enable the service to start automatically at boot
  sudo systemctl enable conky.service
  # Start the service
  sudo systemctl start conky.service
}

run_conf_desktop() {

	#Apply Default font and size
	xfconf-query -c xsettings -p /Gtk/FontName -s "Roboto 10"
	
	#Apply Default Monospace Font and size
	xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s "MesloLGS NF 10"
	
	#Apply Default Theme
	xfconf-query -c xsettings -p /Net/ThemeName -s "Qogir-Dark"
	
	#Apply Default Theme Icons
	xfconf-query -c xsettings -p /Net/IconThemeName -s "Qogir-dark"
	
	#Apply Default Mouse Theme
	xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "Qogir-dark"
	
	#Upload and apply Panel Profile backup
 	unzip xfce4.zip
	xfce4-panel-profiles load "$homedir/debian-desktop/xfce4/xfce4-panel-conf.tar.bz2"
	
	#Apply Default Window Manager Style
	xfconf-query -c xfwm4 -p /general/theme -s "Qogir-Dark"
 
	#Sets the default Window Manager button layout to Minimize, Maximize and Close Top Right
	xfconf-query -c xfwm4 -p /general/button_layout -s "|HMC"
	
	#Sets the Window Manager Title font
	xfconf-query -c xfwm4 -p /general/title_font -s "Roboto Bold 10"
	
	#Disable WIndows Manager Display Composition
	xfconf-query -c xfwm4 -p /general/use_compositing -s false
	
	#Auto Start xbindkeys at login
	echo "xbindkeys &" >> ~/.xinitrc
	
	#Faster Grub
	sudo sed -i 's/GRUB_TIMEOUT=[0-9]\+/GRUB_TIMEOUT=1/' /etc/default/grub && sudo update-grub
	
	# Enable zswap
	sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT/ s/"$/ zswap.enabled=1"/' /etc/default/grub
	sudo update-grub
	
	#Disable Hyper-Thread Mitigations for more performance on Desktop and use zswap
	echo "vm.swappiness = 10" | sudo tee -a /etc/sysctl.conf
	echo "kernel.nosmt = 1" | sudo tee -a /etc/sysctl.conf

}

run_conf_cleanup() {

	sudo nala remove -y \
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

}

#Custom Desktop
run_custom_desktop

#Configures Rofi with xbindkeys After installation
run_conf_rofi

#Configures Picom After installation
run_conf_picom

#Configures Conky After installation
run_conf_conky

#Personalize some settings
run_conf_desktop

#Cleanup
run_conf_cleanup

