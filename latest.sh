# newest version is for a system76 lemur

# assuming wireless network
	rfkill unblock 0
	rfkill unblock 1
	#ip link set wlp1s0 down
	#wifi-menu wlp1s0
    iwctl station wlan0 scan
	iwctl --passphrase=YoMama station wlan0 connect SSIDNAME

# check dhcpd and dns
    systemd-resolve --status

# set time
	#ntpdate pool.ntp.org 
	#hwclock --systohc

# update pacman and system
#	pacman-key --init
#	pacman-key --populate
#	pacman -Syu

# partition BIOS MBR disk (manually for now)
    #fdisk -l
	#cfdisk /dev/sda
		# bios not uefi - see 0uefiboot first
		# new, primary, 20g, bootable
		# new, primary, 1024m, type, swap
		# new, primary, all the rest
		# write, quit
# partition disk with EFI and GPT
	DISK='/dev/nvme0n1'
	( echo o ) | fdisk $DISK
	( 
		echo g
		echo n
		echo 1
		echo
		echo +2G
		echo t
		echo 1
		echo n
		echo 2
		echo 
		echo +450G
		echo n
		echo 3
		echo
		echo
		echo t
		echo 3
		echo 19
		echo w
	) | fdisk $DISK

# install file system on disk, activate swap
	mkfs.fat -F32 /dev/nvme0n1p1
	mkfs.ext4 /dev/nvme0n1p2
	mkswap /dev/nvme0n1p3

# mount file systems and swap
	swapon /dev/nvme0n1p3
	mount /dev/nvme0n1p2 /mnt
	mount --mkdir /dev/nvme0n1p1 /mnt/boot

# bootstrap the new filesystem
	pacstrap /mnt base linux linux-firmware iwd vim git curl
	#genfstab -p /mnt > /mnt/etc/fstab
    genfstab -U /mnt >> /mnt/etc/fstab

# chroot to the new linux system	
	arch-chroot /mnt


###### this part is run inside the chrooted system

# set up language
	sed -i "s/#  en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g" /etc/locale.gen
	echo LANG=en_US.UTF-8 > /etc/locale.conf
	export LANG=en_US.UTF-8
	ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime
	locale-gen

# set hostname, enable dhcp on eth0 interface
	echo ArchTerminal > /etc/hostname
	#sed -i "s/localhost$/localhost ArchTerminal/g" /etc/hosts
	#sed -i "s/#SigLevel\ =\ Optional\ TrustedOnly/SigLevel\ =\ Optional\ TrustedOnly/g" /etc/pacman.conf
    echo 127.0.0.1 localhost > /etc/hosts
	echo ::1 localhost >> /etc/hosts
	echo 127.0.0.1 ArchTerminal >> /etc/hosts

# install packages needed for installation	
	pacman -S iwd wireless_tools netctl wpa_supplicant dialog dhclient grub-bios \
	grub-common os-prober vim efibootmgr sudo ntp
	
# shouldnt have to run wifi-menu at this point, since already connected
	#wifi-menu

# i915 graphics hack if needed
# add intel915 support to boot, run mkinitcpio
	#sed -i "s/MODULES=\"\"/MODULES=\"i915\"/g" /etc/mkinitcpio.conf

# standard stuff	
	mkinitcpio -p linux
	#grub-install --target=i386-pc --recheck /dev/sda
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
	cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
	grub-mkconfig -o /boot/grub/grub.cfg

# disable ipv6
	#sed -i "s/quiet$/ipv6.disable=1/g" /boot/grub/grub.cfg

# set password for root, exit chroot, unmount
	passwd root
	exit #chroot
	reboot 

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
	useradd -G lp,games,video,audio,optical,storage,scanner,power,users,adm -d /home/sysop sysop
	passwd sysop

# sudoers
	echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/suoders.d/wheel_group

# pacman
	sed -i 's/#ParallelDown/ParallelDown' /etc/pacman.conf
	pacman -Syu

# set system time
	#pacman -S ntp
	#ntpdate pool.ntp.org
	timedatectl set-ntp true

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
	pacman -S intel-ucode wget ufw tcpdump openssh tar gzip xz rsync less bat dhcpcd \
	fakeroot bluez-utils 
    systemctl enable --now dhcpcd.service

# enable firewall
	systemctl enable --now ufw.service

# lid switch for laptop
    vim /etc/systemd/logind.conf
	# uncomment HandleLidSwitch=suspend
	systemctl restart systemd-logind.service

####### as non-root user
# aur
	su - sysop
	mkdir ~/checkouts
	cd ~/checkouts
    git clone https://aur.archlinux.org/package-query.git
    cd package-query/
    makepkg -si
    cd ~/checkouts
	git clone https://aur.archlinux.org/yaourt.git
	cd yaourt
	makepkg -si

# additional aur software
	yaourt -S system76-firmware-daemon-git	
	yaourt -S firmware-manager-git
	yaourt -S system76-driver
	yaourt -S system76-acpi-dkms
    yaourt -S brightnessctl
	systemctl enable --now system76
	systemctl enable --now com.system76.PowerDaemon.service
	system76-power profile balanced



# openbox (non-root)
	cd ~	
	mkdir -p .config/openbox
	cp /etc/xdg/openbox/{rc.xml,menu.xml,autostart,environment} ~/.config/openbox
	chmod +x ~/.config/openbox/autostart
	echo "exec openbox-session" > ~/.xinitrc
	systemctl enable slim.service

# sound
	pacman -S alsa-utils alsa-lib pulseaudio
	speaker-test -c 2
    pulseaudio --check
    pulseaudio --start
    amixer sset 'Master' unmute

# xorg trackpad fix
cat << EOF > /etc/X11/xorg.conf.d/40-libinput.conf
Section "InputClass"
        Identifier "libinput touchpad catchall"
        MatchIsTouchpad "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
        Option "Tapping" "on"
        Option "TapButton1" "1"
        Option "TapButton2" "3"
        Option "TapButton3" "2"
        Option "VertTwoFingerScroll" "on"
        Option "HorizTwoFingerScroll" "on"
	Option "NaturalScrolling" "on"
EndSection
EOF

echo alias ls='ls --color=auto' >> /etc/bash.bashrc
echo alias ll='ls -alh' >> /etc/bash.bashrc

# user setup
cp /etc/X11/xinit/xinitrc .xinitrc
