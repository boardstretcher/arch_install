#!/bin/bash

set -e

trap 'if [ $? -eq 0 ]; then echo -e "\nPartitioning completed without errors"; else echo -e "\nPartitioning did NOT complete correctly"; fi' EXIT

lsblk -d -o NAME,SIZE,TYPE | grep 'disk'

echo "Enter the disk you want to partition (e.g., sda, sdb, etc.):"

read DISK

DISK_SIZE=$(lsblk -b -d -o SIZE -n /dev/$DISK)
DISK_SIZE_GIB=$((DISK_SIZE / (1024 * 1024 * 1024)))
RAM_SIZE=$(free -g | awk '/^Mem:/{print $2}')

echo "Selected Disk: /dev/$DISK"
echo "Disk Size: $DISK_SIZE_GIB GiB"
echo "RAM Size: $RAM_SIZE GiB"

echo "WARNING: DELETING DISK $DISK - CTRL-C to EXIT NOW!!!!!"
echo ""
echo "Or Press ENTER to DELETE everything and mount that shit"
read WARNING

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
echo +100G    # Use 100G for root
echo n   # Add a new partition
echo 4   # Partition number
echo     # First sector (Accept default)
echo     # Use rest of disk for home
echo w   # Write changes
) | fdisk /dev/$DISK

mkfs.fat -F32 /dev/${DISK}p1
mkswap /dev/${DISK}p2
mkfs.ext4 /dev/${DISK}p3

cryptsetup --type luks2 luksFormat /dev/${DISK}p4
cryptsetup luksOpen /dev/${DISK}p4 luks
mkfs.ext4 /dev/mapper/luks

swapon /dev/${DISK}p2
mount /dev/${DISK}p3 /mnt
mkdir -p /mnt/boot
mount /dev/${DISK}p1 /mnt/boot
mkdir -p /mnt/home
mount /dev/mapper/luks /mnt/home
