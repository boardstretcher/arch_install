# this part is run inside the chrooted system

# set up language
	sed -i "s/#  en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g" /etc/locale.gen
	echo LANG=en_US.UTF-8 > /etc/locale.conf
	export LANG=en_US.UTF-8
	ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime
	locale-gen

# set hostname, enable dhcp on eth0 interface
	echo ArchTerminal > /etc/hostname
	sed -i "s/localhost$/localhost ArchTerminal/g" /etc/hosts
	# sed -i "s/#SigLevel\ =\ Optional\ TrustedOnly/SigLevel\ =\ Optional\ TrustedOnly/g" /etc/pacman.conf

# install packages needed for installation	
	pacman -S iwd wireless_tools netctl wpa_supplicant dialog dhclient grub-bios \
	grub-common os-prober vim
	
# shouldnt have to run wifi-menu at this point, since already connected
	#wifi-menu

# i915 graphics hack if needed
# add intel915 support to boot, run mkinitcpio
	#sed -i "s/MODULES=\"\"/MODULES=\"i915\"/g" /etc/mkinitcpio.conf

# standard stuff	
	mkinitcpio -p linux
	#grub-install --target=i386-pc --recheck /dev/sda
    grub-install --target=x86_64-efi --efi=directory=/boot --bootloader-id=GRUB
	cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
	grub-mkconfig -o /boot/grub/grub.cfg

# disable ipv6
	#sed -i "s/quiet$/ipv6.disable=1/g" /boot/grub/grub.cfg

# set password for root, exit chroot, unmount
	passwd root
	exit #chroot
	reboot 
