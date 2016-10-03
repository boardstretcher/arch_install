# bring up lan, sync, add a nonroot user
	ip link set wlp1s0 up
	wifi-menu wlp1s0
	pacman --sync --refresh --sysupgrade

	useradd -G lp,games,video,audio,optical,storage,scanner,power,users sysop
	passwd sysop

# set system time
	pacman -S ntp
	ntpdate pool.ntp.org

# Required packages (Window Manager, Sound, Wireless)
	pacman -S alsa-utils xorg-server xorg-xinit xorg-server-utils xf86-video-intel \
	xf86-input-synaptics xterm openbox obconf wget obmenu nitrogen tint2 rox dmenu \
	ristretto volwheel conky xcompmgr rfkill iptables ntfs-3g util-linux \
	acpid gnupg cups gutenprint perl-file-mimeinfo gnome-font-viewer scrot slim


# extra/optional packages (to make a decent desktop)
	pacman -S openbox-themes chromium firefox flashplugin xorg-xev tcpdump openssh \
	rsync xpdf aria2 cups-pdf meld cpio tar gzip zip unzip unrar p7zip arj lha \
	xz lzop w3m  
