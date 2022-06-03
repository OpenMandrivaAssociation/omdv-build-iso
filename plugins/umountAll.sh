#!/bin/sh

# OpenMandriva Association 2022
# Tomasz Paweł Gajc <tpgxyz@gmail.com>

umountAll() {
	printf "%s\n" "-> Unmounting all."
	unset KERNEL_ISO
	umount -l "$1"/proc 2> /dev/null || :
	umount -l "$1"/sys 2> /dev/null || :
	umount -l "$1"/dev/pts 2> /dev/null || :
	umount -l "$1"/dev 2> /dev/null || :
	umount -l "$1"/run/os-prober/dev/* 2> /dev/null || :
	umount -l "$IMGNME" 2> /dev/null || :
}
