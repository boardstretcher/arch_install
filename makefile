.PHONY: all base warning wifi partition mount bootstrap language network \
	packages01 packages02 1915hack bootloader_efi root_user user \
	service_iwd ntp service_dhcpcd service_ufw system76_lidswitch \
	openbox_trackpad ls_colors service_cups service_bluetooth service_network \
	aur_setup system76_software openbox_install audio podman_config \
	flatpak_config flatpak_mega

all: warning
base: wifi partition mount bootstrap language network packages01 packages02 \
	bootloader_efi root_user user pacman

warning:
cat << EOF
Do NOT run all of this makefile at once. 
EOF

wifi:
	read -p "Enter SSID Name: " SSIDNAME
	read -p "Enter SSID Password: " SSIDPW
	rfkill unblock 0
	rfkill unblock 1
	iwctl station wlan0 scan
	iwctl --passphrase=$$SSIDPW station wlan0 connect $$SSIDNAME

partition:
	lsblk -d -o NAME,SIZE,TYPE | grep 'disk'
	echo "Enter the disk you want to partition (e.g., sda, sdb, etc.):"
	read DISK
	DISK_SIZE=$(lsblk -b -d -o SIZE -n /dev/$DISK)
	DISK_SIZE_GIB=$((DISK_SIZE / (1024 * 1024 * 1024)))
	RAM_SIZE=$(free -g | awk '/^Mem:/{print $2}')
	echo "Selected Disk: /dev/$DISK"
	echo "Disk Size: $DISK_SIZE_GIB GiB"
	echo "RAM Size: $RAM_SIZE GiB"

	(
	echo g # Create a new empty GPT partition table
	echo d # Delete the partition
	echo n # Add a new partition
	echo 1 # Partition number
	echo   # First sector (Accept default: 1)
	echo +4G  # Last sector (4G size)
	echo t   # Change partition type
	echo 1   # EFI System
	echo n   # Add a new partition
	echo 2   # Partition number
	echo     # First sector (Accept default)
	echo +"$RAM_SIZE"G # Last sector
	echo n   # Add a new partition
	echo 3   # Partition number
	echo     # First sector (Accept default)
	echo     # Use the rest of the disk
	echo w   # Write changes
	) | fdisk /dev/$DISK
	mkfs.fat -F32 /dev/${DISK}1
	mkswap /dev/${DISK}2
	mkfs.ext4 /dev/${DISK}3

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
	arch-chroot /mnt /bin/bash -c "pacman -Syu --noconfirm intel-ucode wget ufw tcpdump \
	openssh tar gzip xz rsync less bat dhcpcd fakeroot bluez-utils unzip neovim \
 	automake acl autoconf bash-completion podman xdg-desktop-portal xdg-desktop-portal-hyprland \
  	xdg-desktop-portal-gtk gcc yajl pkg-config make linux-headers alsa-utils alsa-lib pulseaudio \
	hyprland waybar rofi slurp grim"

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
	useradd -G lp,games,video,audio,optical,storage,scanner,power,users,adm -d /home/sysop sysop
	echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/suoders.d/wheel_group
	@read -p "Enter new sysop user password: " USERPW
	/bin/bash -c "echo root:$$USERPW | chpasswd"

pacman:
	arch-chroot /mnt /bin/bash -c "sed -i 's/#ParallelDown/ParallelDown' /etc/pacman.conf; \
	pacman -Syu"

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

openbox_trackpad:
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

ls_colors:
	echo alias ls='ls --color=auto' >> /etc/bash.bashrc
	echo alias ll='ls -alh' >> /etc/bash.bashrc

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

aur_setup:
	[ $(id -u) -eq 0 ] && echo "Run as regular user" && exit
	mkdir ~/checkouts
	cd ~/checkouts
	git clone https://aur.archlinux.org/package-query.git
	cd package-query/
	makepkg -si
	cd ~/checkouts
	git clone https://aur.archlinux.org/yaourt.git
	cd yaourt
	makepkg -si

system76_software:
	[ $(id -u) -eq 0 ] && echo "Run as regular user" && exit
	yaourt -S system76-firmware-daemon-git	
	yaourt -S firmware-manager-git
	yaourt -S system76-driver
	yaourt -S system76-acpi-dkms
    	yaourt -S brightnessctl
	systemctl enable --now system76
	systemctl enable --now com.system76.PowerDaemon.service
	system76-power profile balanced

openbox_install:
	[ $(id -u) -eq 0 ] && echo "Run as regular user" && exit
	cd ~	
	mkdir -p .config/openbox
	cp /etc/xdg/openbox/{rc.xml,menu.xml,autostart,environment} ~/.config/openbox
	chmod +x ~/.config/openbox/autostart
	echo "exec openbox-session" > ~/.xinitrc
	systemctl enable slim.service

audio:
	[ $(id -u) -eq 0 ] && echo "Run as regular user" && exit
	pulseaudio --check
	pulseaudio --start
	amixer sset 'Master' unmute
	speaker-test -c 2

podman_config:
cat << EOF > /etc/containers/registries.conf
[registries.search]
registries = ['registry.access.redhat.com', 'registry.redhat.io', 'quay.io', 'docker.io']
EOF
podman search nginx

flatpak_config:
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	flatpak update

flatpak_mega:
	flatpak install nz.mega.MEGAsync
 
