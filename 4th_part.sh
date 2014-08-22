# as non root user

# install X and openbox, create default configuration
	cd ~	
	mkdir -p .config/openbox
	cp /etc/xdg/openbox/{rc.xml,menu.xml,autostart,environment} ~/.config/openbox
	chmod +x ~/.config/openbox/autostart
	echo "exec openbox-session" > ~/.xinitrc
	systemctl enable slim.service
  systemctl enable netctl-auto@wlp18s0.service
	systemctl enable netctl-ifplugd@enp19s0.service
	
	cd ~
	mkdir aur
	cd aur
	wget http://aur.archlinux.org/packages/ya/yaourt/yaourt.tar.gz
	wget http://aur.archlinux.org/packages/pa/package-query/package-query.tar.gz
	tar zxvf yaourt.tar.gz
	tar zxvf package-query.tar.gz
	cd package-query
	makepkg -s
	cd ../yaourt
	makepkg -s
	
	su - -c "cd /home/sysop/aur/package-query; pacman -U package-query-1.0.1-1-i686.pkg.tar.xz; cd ../yaourt; pacman -U yaourt-1.1-1-any.pkg.tar.xz"

	openbox --reconfigure # run this as non-root to reload configuration of openbox
