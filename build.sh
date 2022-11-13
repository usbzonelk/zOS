
if test "`whoami`" != "root" ; then
	echo "You must obtain root status to build (for de-mounting)"
	echo "Enter 'su' or 'sudo bash' to switch to root"
	exit
fi


if [ ! -e disk_images/zOS.flp ]
then
	echo " Creating zOS floppy image..."
	mkdosfs -C disk_images/zOS.flp 1440 || exit
fi


echo " Assembling the bootloader..."

nasm -O0 -w+orphan-labels -f bin -o source/bootload/bootload.bin source/bootload/bootload.asm || exit


echo " Assembling the kernel..."

cd source
nasm -O0 -w+orphan-labels -f bin -o kernel.bin kernel.asm || exit
cd ..

echo " Adding bootloader to floppy image..."

dd status=noxfer conv=notrunc if=source/bootload/bootload.bin of=disk_images/zOS.flp || exit


echo " Copying the kernel and programs..."

rm -rf tmp-loop

mkdir tmp-loop && mount -o loop -t vfat disk_images/zOS.flp tmp-loop && cp source/kernel.bin tmp-loop/

cp programs/sample.pcx tmp-loop

sleep 0.2

echo " Rolling back loopback floppy..."

umount tmp-loop || exit

rm -rf tmp-loop

echo " Generating CD-ROM ISO image..."

rm -f disk_images/zOS.iso
mkisofs -quiet -V 'zOS' -input-charset iso8859-1 -o disk_images/zOS.iso -b zOS.flp disk_images/ || exit

echo 'Opening QEMU...'

qemu-system-i386 -fda ./disk_images/zOS.flp || exit

