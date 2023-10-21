DISK=/dev/nvme0n1

.PHONY: all wifi partition filesystem bootstrap

all: warning
base: wifi partition filesystem bootstrap language network packages01 packages02 \
user pacman bootloader_efi root_user

warning:
cat << EOF
Do NOT run all of this makefile at once. 
EOF

wifi:
	@read -p "Enter SSID Name: " SSIDNAME; \
	read -p "Enter SSID Password: " SSIDPW; \
	rfkill unblock 0; \
	rfkill unblock 1; \
	iwctl station wlan0 scan; \
	iwctl --passphrase=$(SSIDPW) station wlan0 connect $(SSIDNAME)

partition:
	( echo o ) | fdisk $(DISK)
	( \
		echo g; \
		echo n; \
		echo 1; \
		echo ; \
		echo +2G; \
		echo t; \
		echo 1; \
		echo n; \
		echo 2; \
		echo ; \
		echo +450G; \
		echo n; \
		echo 3; \
		echo ; \
		echo ; \
		echo t; \
		echo 3; \
		echo 19; \
		echo w; \
	) | fdisk $(DISK)

filesystem:
	mkfs.fat -F32 /dev/nvme0n1p1
	mkfs.ext4 /dev/nvme0n1p2
	mkswap /dev/nvme0n1p3

mount:
	swapon /dev/nvme0n1p3
	mount /dev/nvme0n1p2 /mnt
	mkdir -p /mnt/boot
	mount /dev/nvme0n1p1 /mnt/boot

bootstrap:
	pacstrap /mnt base linux linux-firmware iwd vim git curl
	genfstab -U /mnt >> /mnt/etc/fstab

language:
	arch-chroot /mnt /bin/bash -c "echo setting language;\
	sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen;\
	echo LANG=en_US.UTF-8 > /etc/locale.conf;\
	export LANG=en_US.UTF-8;\
	ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime;\
	locale-gen;"

network:
	arch-chroot /mnt /bin/bash -c "echo configuring network;\
	echo ArchTerminal > /etc/hostname;\
        echo 127.0.0.1 localhost > /etc/hosts;\
	echo ::1 localhost >> /etc/hosts;\
	echo 127.0.0.1 ArchTerminal >> /etc/hosts;"

packages01:
	arch-chroot /mnt /bin/bash -c "pacman -Syu --noconfirm iwd wireless_tools \
	netctl wpa_supplicant dialog dhclient grub-bios \
	grub-common os-prober vim efibootmgr sudo ntp"

packages02:
	arch-chroot /mnt /bin/bash -c "pacman -Syu --noconfirm intel-ucode wget ufw tcpdump openssh tar gzip xz rsync less bat dhcpcd \
	fakeroot bluez-utils unzip nitrogen tint2 slim slim-themes dmenu cups xorg-server xorg-xinit \
 	openbox automake acl autoconf picom util-linux bash-completion podman zenity xdg-desktop-portal \
  	xdg-desktop-portal-gtk gcc yajl pkg-config make linux-headers"

1915hack:
	sed -i "s/MODULES=\"\"/MODULES=\"i915\"/g" /etc/mkinitcpio.conf

bootloader_efi:
	arch-chroot /mnt /bin/bash -c "mkinitcpio -p linux; \
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch; \
	cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo; \
	grub-mkconfig -o /boot/grub/grub.cfg;"

root_user:
	@read -p "Enter root password: " ROOTPW; \
	arch-chroot /mnt /bin/bash -c "echo $(ROOTPW) | passwd --stdin root"

user:
	useradd -G lp,games,video,audio,optical,storage,scanner,power,users,adm -d /home/sysop sysop
	passwd sysop
	echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/suoders.d/wheel_group

pacman:
	sed -i 's/#ParallelDown/ParallelDown' /etc/pacman.conf
	pacman -Syu

service_iwd:
    systemctl enable --now iwd.service
    iwctl station wlan0 scan
	iwctl --passphrase=YoMama station wlan0 connect SSIDNAME
	dhclient

ntp:
	timedatectl set-ntp true


# add this to each loader line in grub.cfg
	initrd /intel-ucode.img

service_dhcpcd:
	systemctl enable --now dhcpcd.service

service_ufw:
	systemctl enable --now ufw.service
 	ufw default deny incoming
	ufw default allow outgoing
 	ufw enable

system76_lidswitch:
    vim /etc/systemd/logind.conf
	# uncomment HandleLidSwitch=suspend
	systemctl restart systemd-logind.service

service_cups:
	pacman -S cups hplip
	systemctl enable --now cups.service

service_bluetooth:
	pacman -S bluez-utils pulseaudio-bluetooth blueman
	systemctl enable --now bluetooth.service
	echo "run blueman-manager to connect"

service_network:
	systemctl enable systemd-networkd
	systemctl enable systemd-resolved


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

# additional system76 software
	yaourt -S system76-firmware-daemon-git	
	yaourt -S firmware-manager-git
	yaourt -S system76-driver
	yaourt -S system76-acpi-dkms
    	yaourt -S brightnessctl
	systemctl enable --now system76
	systemctl enable --now com.system76.PowerDaemon.service
	system76-power profile balanced

# additional aur software
	yaourt -S hstr

# openbox (non-root)
	cd ~	
	mkdir -p .config/openbox
	cp /etc/xdg/openbox/{rc.xml,menu.xml,autostart,environment} ~/.config/openbox
	chmod +x ~/.config/openbox/autostart
	echo "exec openbox-session" > ~/.xinitrc
	systemctl enable slim.service

# sound
    pacman -S alsa-utils alsa-lib pulseaudio
    pulseaudio --check
    pulseaudio --start
    amixer sset 'Master' unmute
	speaker-test -c 2

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

# ls colors fix
	echo alias ls='ls --color=auto' >> /etc/bash.bashrc
	echo alias ll='ls -alh' >> /etc/bash.bashrc

# user setup
	echo 'exec openbox-session' > ~/.xinitrc

# podman setup
cat << EOF > /etc/containers/registries.conf
[registries.search]
registries = ['registry.access.redhat.com', 'registry.redhat.io', 'quay.io', 'docker.io']
EOF
podman search nginx

# flatpak setup
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	flatpak update

# additional applications
	flatpak install nz.mega.MEGAsync
 
