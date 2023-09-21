# bring up lan, sync, add a nonroot user
	rfkill unblock 0
	rfkill unblock 1

# enable iwd
    systemctl enable --now iwd.service
    iwctl station wlan0 scan
	iwctl --passphrase=YoMama station wlan0 connect SSIDNAME
	dhclient

# check dhcpd and dns
    systemd-resolve --status

# user
	useradd -G lp,games,video,audio,optical,storage,scanner,power,users -d /home/sysop sysop
	passwd sysop

# sudoers
	echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/suoders.d/wheel_group

# pacman
	sed -i 's/#ParallelDown/ParallelDown' /etc/pacman.conf
	pacman -Syu

# set system time
	pacman -S ntp
	ntpdate pool.ntp.org

# Required packages (Window Manager, Sound, Wireless)
	#pacman -S alsa-utils xorg-server xorg-xinit xorg-server-utils xf86-video-intel \
	#xf86-input-synaptics xterm openbox obconf wget obmenu nitrogen tint2 rox dmenu \
	#ristretto volwheel conky xcompmgr rfkill iptables ntfs-3g util-linux \
	#acpid gnupg cups gutenprint perl-file-mimeinfo gnome-font-viewer scrot slim


# extra/optional packages (to make a decent desktop)
	#pacman -S openbox-themes chromium firefox flashplugin xorg-xev tcpdump openssh \
	#rsync xpdf aria2 cups-pdf meld cpio tar gzip zip unzip unrar p7zip arj lha \
	#xz lzop w3m  

# keeping it minimal
	pacman -S intel-ucode wget ufw tcpdump openssh tar gzip xz rsync less bat

# enable firewall
	systemctl enable --now ufw.service

# aur
	su - sysop
	mkdir checkouts
	cd checkouts
	git clone https://aur.archlinux.org/paru-bin.git
	
