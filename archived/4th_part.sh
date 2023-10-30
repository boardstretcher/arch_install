# as non root user

# install X and openbox, create default configuration
	cd ~	
	mkdir -p .config/openbox
	cp /etc/xdg/openbox/{rc.xml,menu.xml,autostart,environment} ~/.config/openbox
	chmod +x ~/.config/openbox/autostart
	echo "exec openbox-session" > ~/.xinitrc
	systemctl enable slim.service
        systemctl enable netctl-auto@wlp1s0.service
	systemctl enable netctl-ifplugd@enp1s0.service

	openbox --reconfigure # run this as non-root to reload configuration of openbox
	
	pacman -S subversion git cvs aircrack-ng aircrack-ng-scripts ipcalc mysql-clients dnstracer dsniff \
	geoip geany php gdb strace minicom mtr dnsutils remmina freerdp kismet lshw lsof macchanger nbtscan \
	john ngrep arpwatch apg netcat screen whois glances openvpn virtualbox pulseaudio aria2 \
	bleachbit cheese clamav dosbox fontconfig gparted imagemagick ipcalc kismet kvirc macchanger \
	gcalctool gucharmap rapidsvn imagemagick gimp wireshark-gtk pinta mtpaint xv gimp bleachbit\
	
