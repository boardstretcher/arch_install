DISK=/dev/nvme0n1

.PHONY: all wifi partition filesystem bootstrap

all: wifi partition filesystem bootstrap
base: wifi partition filesystem bootstrap

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

