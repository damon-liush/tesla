tools/qemu-5.1.0/build/riscv64-softmmu/qemu-system-riscv64 -M virt -m 256M -nographic \
        -bios output/fw_jump.bin \
        -kernel output/Image \
        -append "root=/dev/vda ro console=ttyS0" \
        -drive file=output/busybear.bin,format=raw,id=hd0 -device virtio-blk-device,drive=hd0
