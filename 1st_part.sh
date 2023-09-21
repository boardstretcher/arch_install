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
