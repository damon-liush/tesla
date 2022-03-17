#!/bin/bash
# **********************************************************
# * Author        : damon
# * Email         : lshua312@163.com
# * Create Time   : 2022-03-17 13:18:32
# * File Name     : mk.sh
# * Description   : 
# **********************************************************

WORK_TESLA_PATH="`pwd`"
echo $WORK_TESLA_PATH
TESLA_KERNEL_PATH=${WORK_TESLA_PATH}/linux
TESLA_OUTPUT_PATH=${WORK_TESLA_PATH}/output
TESLA_BBL_PATH=${WORK_TESLA_PATH}/opensbi
TESLA_CROSS_COMPILE=gcc
TESLA_GNU_TOOLS_REPO_PATH=${WORK_TESLA_PATH}/riscv-gnu-toolchain

#BBL_PATH=${WORK_QEMU_PATH}riscv-pk/


#create output dir
if [ ! -d output ] ; then
        mkdir output
fi
#prepare toolchains
if [ ! -d ${WORK_TESLA_PATH}/output/riscv64-gnu-toolchain-compiler ] ; then
     #   tar -xzvf ${WORK_TESLA_PATH}/tools/riscv64-gnu-toolchain-self-compiler.tar.gz -C ${WORK_TESLA_PATH}/output
     GNU_TOOLS_INSTALL_PATH=${WORK_TESLA_PATH}/output/riscv64-gnu-toolchain-compiler
     mkdir ${GNU_TOOLS_INSTALL_PATH}
     cd ${TESLA_GNU_TOOLS_REPO_PATH}
     ./configure --prefix=${GNU_TOOLS_INSTALL_PATH}
     make linux
     if [ $? -eq 0 ];then
	     echo "compiler is ok"
     else
	     echo "compiler is fail"
	     rm ${GNU_TOOLS_INSTALL_PATH} -f
     fi
fi

exit 0

TESLA_CROSS_COMPILE=${WORK_TESLA_PATH}/output/riscv64-gnu-toolchain-self-compiler/bin/riscv64-unknown-linux-gnu-
if [ ! -f ${TESLA_CROSS_COMPILE}gcc ]; then
        echo "compiler err:"${TESLA_CROSS_COMPILE} "is not exited"
        exit 1
fi


#compile linux
cd ${TESLA_KERNEL_PATH}
if [ ! -f .config ] ; then
        make ARCH=riscv defconfig
fi
make vmlinux CROSS_COMPILE=${TESLA_CROSS_COMPILE} ARCH=riscv
make modules CROSS_COMPILE=${TESLA_CROSS_COMPILE} ARCH=riscv
make Image CROSS_COMPILE=${TESLA_CROSS_COMPILE} ARCH=riscv

if [ ! -f vmlinux ] ; then
        echo "vmlinux not exist, kernel compile failed."
        exit 1
fi

if [ ! -f ${TESLA_KERNEL_PATH}/arch/riscv/boot/Image ] ; then
        echo "Image not exist, kernel compile failed."
        exit 1
fi
cp ${TESLA_KERNEL_PATH}/arch/riscv/boot/Image ${TESLA_OUTPUT_PATH}

#compile bbl
cd ${TESLA_BBL_PATH}
make distclean
make PLATFORM=generic CROSS_COMPILE=${TESLA_CROSS_COMPILE} PLATFORM_RISCV_ISA=rv64gcv

if [ ! -f ${TESLA_BBL_PATH}/build/platform/generic/firmware/fw_jump.bin ] ; then
        echo "fw_jump.bin not exist, opensbi compile failed."
        exit 1
fi
cp ${TESLA_BBL_PATH}/build/platform/generic/firmware/fw_jump.bin ${TESLA_OUTPUT_PATH}
