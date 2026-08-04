srcdir := justfile_directory()

docker_image := "debian-sarge-builder-i386"
docker_flags := "--rm -i -v " + srcdir + ":" + srcdir + " -w " + srcdir

# Build the kernel (defconfig + enable required configs + make)
build:
    #!/bin/bash
    set -eu
    set -x
    cd "{{srcdir}}"

    # defconfig (only if .config doesn't exist)
    if [ ! -f build/.config ]; then
        echo "=== Running defconfig ==="
        mkdir -p build
        docker run {{docker_flags}} {{docker_image}} bash -c 'make ARCH=i386 O=build defconfig'
    fi

    # Enable required config options
    echo "=== Enabling required configs ==="
    misc/kconfig-enable build/.config \
        CONFIG_SERIAL_8250_CONSOLE CONFIG_BLK_DEV_RAM CONFIG_DEBUG_KERNEL \
        CONFIG_BLK_DEV_INITRD CONFIG_DEBUG_INFO

    # oldconfig to resolve new dependencies
    echo "=== Running oldconfig ==="
    docker run {{docker_flags}} {{docker_image}} bash -c 'yes "" | make ARCH=i386 O=build oldconfig > /dev/null 2>&1'

    # Build
    echo "=== Building kernel ==="
    docker run  --hostname builder {{docker_flags}} {{docker_image}} bash -c 'make ARCH=i386 O=build -j12'

# Build minimal initramfs (single C init, prints message and reboots)
cpio-minimal:
    make -C misc/initramfs cpio

# Build busybox (+ clone source if needed)
busybox:
    make -C misc/busybox busybox

# Build busybox initramfs (shell environment)
cpio-busybox:
    make -C misc/busybox cpio

# Run kernel in QEMU (minimal initramfs)
run-minimal: build cpio-minimal
    qemu-system-i386 \
        -kernel build/arch/i386/boot/bzImage \
        -initrd build/initramfs-minimal.cpio.gz \
        -append "console=ttyS0" \
        -nographic -no-reboot -m 256M

# Run kernel with BusyBox initramfs
run-busybox: build cpio-busybox
    qemu-system-i386 \
        -kernel build/arch/i386/boot/bzImage \
        -initrd build/initramfs-busybox.cpio.gz \
        -append "console=ttyS0" \
        -nographic -no-reboot -m 256M

# Debug kernel with GDB (QEMU gdbserver on :1234, breaks at start_kernel)
debug: build cpio-minimal
    #!/bin/bash
    set -eu
    cd "{{srcdir}}"
    echo "=== Starting QEMU with GDB server on :1234 ==="
    echo 'gdb build/vmlinux  -ex "target remote :1234" -ex "hb start_kernel" -ex "c"'
    echo "=== Connecting GDB ==="
    qemu-system-i386 \
        -kernel build/arch/i386/boot/bzImage \
        -initrd build/initramfs-minimal.cpio.gz \
        -append "console=ttyS0 nokaslr" \
        -nographic -no-reboot -m 256M \
        -s -S

# Clean all build artifacts
clean:
    rm -rf build
