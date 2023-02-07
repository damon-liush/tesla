#!/bin/bash
# **********************************************************
# * Author        : damon
# * Email         : lshua312@163.com
# * Create Time   : 2023-02-04
# * File Name     : topmk.sh
# * Description   : 
# **********************************************************

set -e

WORK_TOP_PATH="`pwd`"
echo $WORK_TOP_PATH
WORK_KERNEL_PATH=${WORK_TOP_PATH}/linux
WORK_OUTPUT_PATH=${WORK_TOP_PATH}/output
WORK_SBI_PATH=${WORK_TOP_PATH}/opensbi
WORK_ROOTFS_PATH=${WORK_TOP_PATH}/buildroot
WORK_QEMU_PATH=${WORK_TOP_PATH}/qemu
WORK_GNU_TOOLS_REPO_PATH=${WORK_TOP_PATH}/riscv-gnu-toolchain
WORK_CROSS_COMPILE=riscv64-unknown-linux-gnu-
GNU_TOOLS_INSTALL_PATH=/opt/riscv64

#mk buildroot
#mk qemu
#mk tools

mktools(){
	if $(command -v riscv64-unknown-linux-gnu-gcc > /dev/null)
	then
		echo "RISCV tools were installed on host."
		WORK_CROSS_COMPILE=riscv64-unknown-linux-gnu-
		${WORK_CROSS_COMPILE}gcc -v
	elif [ -f ${WORK_CROSS_COMPILE}gcc ]
		echo "RISCV GNU tools were compiled and installed."
	then
		echo "Installing the RISC-V tools"
		# GNU_TOOLS_INSTALL_PATH=${WORK_TOP_PATH}/output/compiler
		# mkdir -p ${GNU_TOOLS_INSTALL_PATH}
		cd ${WORK_GNU_TOOLS_REPO_PATH}
		mkdir build
		cd build
		./configure --prefix=${GNU_TOOLS_INSTALL_PATH}
		make linux
		if [ $? -eq 0 ];then
			echo "tools is ready"
		else
			echo "tools install fail"
			#rm ${GNU_TOOLS_INSTALL_PATH} -f
		fi
		make install
	fi
}

mkrootfs(){
	cd ${WORK_ROOTFS_PATH}
	if [ ! -f .config ] ; then
		make qemu_riscv64_virt_defconfig
	fi
	make
}


mklinux(){
	cd ${WORK_KERNEL_PATH}
	if [ ! -f .config ] ; then
        	make ARCH=riscv defconfig
	fi

	make vmlinux CROSS_COMPILE=${WORK_CROSS_COMPILE} ARCH=riscv
	make modules CROSS_COMPILE=${WORK_CROSS_COMPILE} ARCH=riscv
	make Image CROSS_COMPILE=${WORK_CROSS_COMPILE} ARCH=riscv

	if [ ! -f ${WORK_KERNEL_PATH}/arch/riscv/boot/Image ] ; then
        	echo "Image not exist, kernel compile failed."
        	exit 1
	fi

	cp ${WORK_KERNEL_PATH}/arch/riscv/boot/Image ${WORK_OUTPUT_PATH}
	cp ${WORK_KERNEL_PATH}/vmlinux ${WORK_OUTPUT_PATH}
}

mksbi(){
	cd ${WORK_SBI_PATH}
	make distclean
	make PLATFORM=generic CROSS_COMPILE=${WORK_CROSS_COMPILE}

	if [ ! -f ${WORK_SBI_PATH}/build/platform/generic/firmware/fw_jump.bin ] ; then
		echo "fw_jump.bin not exist, opensbi compile failed."
		exit 1
	fi
	cp ${WORK_SBI_PATH}/build/platform/generic/firmware/fw_jump.bin ${WORK_OUTPUT_PATH}
	cp ${WORK_SBI_PATH}/build/platform/generic/firmware/fw_jump.elf ${WORK_OUTPUT_PATH}
}

mkqemu(){
	cd ${WORK_QEMU_PATH}
	mkdir build
	cd build
	../configure --target-list=riscv64-softmmu,riscv64-linux-user --prefix=/opt/qemu
	make -j2
	make install
}

packout(){
	echo "todo..."
}

#create output dir and link files
cd ${WORK_TOP_PATH}
if [ ! -d output ] ; then
        mkdir output
fi


case $1 in
    "all")
        echo "build kernel sbi rootfs ..."
	mklinux
	mksbi
	mkrootfs
        ;;
    "kernel")
        echo "build kernel ..."
	mklinux
        ;;
    "rootfs")
        echo "build rootfs ..."
	mkrootfs
        ;;
    "sbi")
        echo "build sbi ..."
	mksbi
        ;;
    "qemu")
        echo "build qemu ..."
	mkqemu
        ;;
    "tools")
        echo "build gnu tools ..."
	mktools
        ;;
    "pack")
        echo "pack linux opensbi rootfs to output ..."
	packout
        ;;
    *)
    echo "Your cmd is error!"
    ;;
esac
