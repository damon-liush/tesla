#!/bin/bash
# **********************************************************
# * Author        : damon
# * Email         : lshua312@163.com
# * Create Time   : 2022-03-17 13:18:32
# * File Name     : mk.sh
# * Description   : 
# **********************************************************

set -e

WORK_TESLA_PATH="`pwd`"
echo $WORK_TESLA_PATH
TESLA_KERNEL_PATH=${WORK_TESLA_PATH}/linux
TESLA_OUTPUT_PATH=${WORK_TESLA_PATH}/output
TESLA_SBI_PATH=${WORK_TESLA_PATH}/opensbi
TESLA_GNU_TOOLS_REPO_PATH=${WORK_TESLA_PATH}/riscv-gnu-toolchain
TESLA_CROSS_COMPILE=${WORK_TESLA_PATH}/output/compiler/bin/riscv64-unknown-linux-gnu-


#create output dir
if [ ! -d output ] ; then
        mkdir output
fi
#prepare toolchains
if $(command -v riscv64-unknown-linux-gnu-gcc > /dev/null)
then
       echo "RISCV tools were installed on host."
       TESLA_CROSS_COMPILE=riscv64-unknown-linux-gnu-
elif [ -f ${TESLA_CROSS_COMPILE}gcc ]
       echo "RISCV GNU tools were compiled and installed."
then
       echo "Installing the RISC-V tools"
       GNU_TOOLS_INSTALL_PATH=${WORK_TESLA_PATH}/output/compiler
       mkdir -p ${GNU_TOOLS_INSTALL_PATH}
       cd ${TESLA_GNU_TOOLS_REPO_PATH}
       ./configure --prefix=${GNU_TOOLS_INSTALL_PATH}
       make linux
       if [ $? -eq 0 ];then
               echo "compiler is ok"
       else
               echo "compiler is fail"
               rm ${GNU_TOOLS_INSTALL_PATH} -f
       fi
       make install
fi


#compile linux
cd ${TESLA_KERNEL_PATH}
if [ ! -f .config ] ; then
        make ARCH=riscv defconfig
fi
make vmlinux CROSS_COMPILE=${TESLA_CROSS_COMPILE} ARCH=riscv
make modules CROSS_COMPILE=${TESLA_CROSS_COMPILE} ARCH=riscv
make Image CROSS_COMPILE=${TESLA_CROSS_COMPILE} ARCH=riscv

if [ ! -f ${TESLA_KERNEL_PATH}/arch/riscv/boot/Image ] ; then
        echo "Image not exist, kernel compile failed."
        exit 1
fi

cp ${TESLA_KERNEL_PATH}/arch/riscv/boot/Image ${TESLA_OUTPUT_PATH}
cp ${TESLA_KERNEL_PATH}/vmlinux ${TESLA_OUTPUT_PATH}

#compile sbi
cd ${TESLA_SBI_PATH}
make distclean
make PLATFORM=generic CROSS_COMPILE=${TESLA_CROSS_COMPILE} PLATFORM_RISCV_ISA=rv64gcv

if [ ! -f ${TESLA_SBI_PATH}/build/platform/generic/firmware/fw_jump.bin ] ; then
        echo "fw_jump.bin not exist, opensbi compile failed."
        exit 1
fi
cp ${TESLA_SBI_PATH}/build/platform/generic/firmware/fw_jump.bin ${TESLA_OUTPUT_PATH}
