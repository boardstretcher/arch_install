# assuming wireless network
	rfkill unblock 0
	rfkill unblock 1
	ip link set wlp1s0 down
	wifi-menu wlp1s0

# set time
	ntpdate pool.ntp.org 
	hwclock --systohc

# update pacman and system
#	pacman-key --init
#	pacman-key --populate
#	pacman -Syu

# partition disk (manually for now)

	cfdisk /dev/sda
		# new, primary, 20g, bootable
		# new, primary, 1024m, type, swap
		# new, primary, all the rest
		# write, quit

# install file system on disk, activate swap
	mkfs.ext4 /dev/sda1
	mkfs.ext4 /dev/sda3
	mkswap /dev/sda2

# mount file systems and swap
	swapon /dev/sda2
	mount /dev/sda1 /mnt
	mkdir /mnt/home
	mount /dev/sda3 /mnt/home

# bootstrap the new filesystem
	pacstrap /mnt base base-devel
	genfstab -p /mnt > /mnt/etc/fstab

# chroot to the new linux system	
	arch-chroot /mnt
