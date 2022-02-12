WORK_HGMINI_PATH="`pwd`"
echo $WORK_HGMINI_PATH
HGMINI_KERNEL_PATH=${WORK_HGMINI_PATH}/linux
HGMINI_OUTPUT_PATH=${WORK_HGMINI_PATH}/output
HGMINI_BBL_PATH=${WORK_HGMINI_PATH}/opensbi
HGMINI_CROSS_COMPILE=gcc

#BBL_PATH=${WORK_QEMU_PATH}riscv-pk/


#create output dir
if [ ! -d output ] ; then
        mkdir output
fi
#prepare toolchains
if [ ! -d ${WORK_HGMINI_PATH}/output/riscv64-gnu-toolchain-self-compiler ] ; then
        tar -xzvf ${WORK_HGMINI_PATH}/tools/riscv64-gnu-toolchain-self-compiler.tar.gz -C ${WORK_HGMINI_PATH}/output
fi

HGMINI_CROSS_COMPILE=${WORK_HGMINI_PATH}/output/riscv64-gnu-toolchain-self-compiler/bin/riscv64-unknown-linux-gnu-
if [ ! -f ${HGMINI_CROSS_COMPILE}gcc ]; then
        echo "compiler err:"${HGMINI_CROSS_COMPILE} "is not exited"
        exit 1
fi


#compile linux
cd ${HGMINI_KERNEL_PATH}
if [ ! -f .config ] ; then
        make ARCH=riscv defconfig
fi
make vmlinux CROSS_COMPILE=${HGMINI_CROSS_COMPILE} ARCH=riscv
make modules CROSS_COMPILE=${HGMINI_CROSS_COMPILE} ARCH=riscv
make Image CROSS_COMPILE=${HGMINI_CROSS_COMPILE} ARCH=riscv

if [ ! -f vmlinux ] ; then
        echo "vmlinux not exist, kernel compile failed."
        exit 1
fi

if [ ! -f ${HGMINI_KERNEL_PATH}/arch/riscv/boot/Image ] ; then
        echo "Image not exist, kernel compile failed."
        exit 1
fi
cp ${HGMINI_KERNEL_PATH}/arch/riscv/boot/Image ${HGMINI_OUTPUT_PATH}

#compile bbl
cd ${HGMINI_BBL_PATH}
make distclean
make PLATFORM=generic CROSS_COMPILE=${HGMINI_CROSS_COMPILE} PLATFORM_RISCV_ISA=rv64gcv

if [ ! -f ${HGMINI_BBL_PATH}/build/platform/generic/firmware/fw_jump.bin ] ; then
        echo "fw_jump.bin not exist, opensbi compile failed."
        exit 1
fi
cp ${HGMINI_BBL_PATH}/build/platform/generic/firmware/fw_jump.bin ${HGMINI_OUTPUT_PATH}
