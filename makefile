# add this to each loader line in grub.cfg
#initrd /intel-ucode.img

# NOTE: to get make and git on a new arch install, be sure to only run 
# pacman -Sy so that the kernel versions dont conflict while 
# installing

# On a newly booted USB Arch ISO you will want to:
#
# ./script_wifi.sh
# pacman -Sy
# ./script_partition.sh
# make base
# reboot
#
# Then once rebooted and in the new arch system
# 
#
#
.PHONY: all base warning wifi partition mount bootstrap language network \
	packages01 packages02 1915hack bootloader_efi root_user user \
	service_iwd ntp service_dhcpcd service_ufw fix_lidswitch \
	fix_trackpad config_ls service_cups service_bluetooth service_network \
	USER_aur_setup USER_software01 USER_system76_software USER_openbox_install \
	USER_audio USER_podman_config USER_flatpak_config USER_flatpak_mega userinstall

all: warning

base: bootstrap language network packages01 packages02 bootloader_efi root_user user pacman

firstboot: ntp service_dhcpcd service_ufw fix_lidswitch config_ls service_bluetooth \
	service_network 

userinstall: USER_aur_setup USER_software01 USER_audio USER_flatpak_config \
	USER_flatpak_mega
	./script_vim.sh	

warning:
	echo "Do NOT run all of this makefile at once." 

wifi: service_iwd
	./script_wifi.sh
	dhclient

partition:
	./script_partition.sh

bootstrap:
	pacstrap /mnt base linux linux-firmware iwd vim git curl bat
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
	netctl wpa_supplicant dialog dhclient grub-bios grub-common os-prober 
	vim efibootmgr sudo ntp cpupower intel-ucode wget ufw tcpdump sed which grep \
	openssh tar gzip xz rsync less bat dhcpcd fakeroot bluez-utils unzip neovim \
 	automake acl autoconf bash-completion podman  gcc yajl pkg-config make awk \
	linux-headers alsa-utils alsa-lib pulseaudio man-db flatpak"

packages02:
	arch-chroot /mnt /bin/bash -c "pacman -Syu --noconfirm otf-font-awesome \
	xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
	hyprland waybar rofi slurp grim kitty terminator firefox swaylock dunst \
	bottom neofetch"

1915hack:
	sed -i "s/MODULES=\"\"/MODULES=\"i915\"/g" /etc/mkinitcpio.conf

bootloader_efi:
	arch-chroot /mnt /bin/bash -c "mkinitcpio -p linux; \
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch; \
	cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo; \
	grub-mkconfig -o /boot/grub/grub.cfg;"

root_user:
	@read -p "Enter new root password: " ROOTPW; \
	arch-chroot /mnt /bin/bash -c "echo root:$$ROOTPW | chpasswd"

user:
	arch-chroot /mnt /bin/bash -c 'echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel_group;'
	arch-chroot /mnt /bin/bash -c 'useradd -G lp,games,video,audio,optical,storage,scanner,power,users,adm -d /home/sysop sysop;'
	@read -p "Enter new sysop user password: " USERPW \
	arch-chroot /mnt /bin/bash -c "echo root:$$USERPW | chpasswd"

pacman:
	arch-chroot /mnt /bin/bash -c "sed -i 's/#ParallelDown/ParallelDown' /etc/pacman.conf; \
	pacman -Syu"

service_iwd:
	systemctl enable --now iwd.service

ntp:
	timedatectl set-ntp true


service_dhcpcd:
	systemctl enable --now dhcpcd.service

service_ufw:
	systemctl enable --now ufw.service
	ufw default deny incoming
	ufw default allow outgoing
	ufw enable

fix_lidswitch:
	sed -i 's/#HandleLidSwitch=suspend/HandleLidSwitch=suspend/g' /etc/systemd/logind.conf
	systemctl restart systemd-logind.service

fix_trackpad:
	bash -c '\
	cat << EOF > /etc/X11/xorg.conf.d/40-libinput.conf \
	Section "InputClass" \
        Identifier "libinput touchpad catchall" \
        MatchIsTouchpad "on" \
        MatchDevicePath "/dev/input/event*" \
        Driver "libinput" \
        Option "Tapping" "on" \
        Option "TapButton1" "1" \
        Option "TapButton2" "3" \
        Option "TapButton3" "2" \
        Option "VertTwoFingerScroll" "on" \
        Option "HorizTwoFingerScroll" "on" \
	Option "NaturalScrolling" "on" \
EndSection \
EOF \
'

config_ls:
	echo alias ls="ls --color=auto" >> /etc/bash.bashrc
	echo alias ll="ls -alh" >> /etc/bash.bashrc

service_cups:
	pacman -Syu --noconfirm cups hplip
	systemctl enable --now cups.service

service_bluetooth:
	pacman -Syu --noconfirm bluez-utils pulseaudio-bluetooth blueman
	systemctl enable --now bluetooth.service
	echo "run blueman-manager to connect"

service_network:
	#systemctl enable systemd-networkd
	systemctl enable systemd-resolved

USER_aur_setup:
	mkdir -p ~/checkouts
	cd ~/checkouts;	git clone https://aur.archlinux.org/package-query.git
	cd ~/checkouts/package-query; makepkg -si --noconfirm
	cd ~/checkouts;	git clone https://aur.archlinux.org/yaourt.git
	cd ~/checkouts/yaourt; makepkg -si --noconfirm

USER_system76_software:
	yaourt -S --noconfirm system76-firmware-daemon-git	
	yaourt -S --noconfirm firmware-manager-git
	yaourt -S --noconfirm system76-driver
	yaourt -S --noconfirm system76-acpi-dkms
	systemctl enable --now system76
	systemctl enable --now com.system76.PowerDaemon.service
	system76-power profile balanced

USER_software01:
	yaourt -S --noconfirm brightnessctl

USER_openbox_install:
	cd ~	
	mkdir -p .config/openbox
	cp /etc/xdg/openbox/{rc.xml,menu.xml,autostart,environment} ~/.config/openbox
	chmod +x ~/.config/openbox/autostart
	echo "exec openbox-session" > ~/.xinitrc
	systemctl enable slim.service

USER_audio:
	pulseaudio --check
	pulseaudio --start
	amixer sset 'Master' unmute
	#speaker-test -c 2

USER_podman_config:
	sudo echo -e "[registries.search] \n registries = ['registry.access.redhat.com', 'registry.redhat.io', 'quay.io', 'docker.io']" > /etc/containers/registries.conf
	podman search nginx

USER_flatpak_config:
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	flatpak update

USER_flatpak_mega:
	flatpak install nz.mega.MEGAsync
