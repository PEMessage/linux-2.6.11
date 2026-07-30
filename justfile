srcdir := justfile_directory()

docker_image := "debian-sarge-builder-i386"
docker_flags := "--rm -i -v " + srcdir + ":" + srcdir + " -w " + srcdir

# Build the kernel (defconfig + enable required configs + make)
build:
    #!/bin/bash
    set -eu
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
    docker run {{docker_flags}} {{docker_image}} bash -c 'make ARCH=i386 O=build -j$(nproc)'

# Build initramfs cpio
cpio:
    #!/bin/bash
    set -eu
    cd "{{srcdir}}"

    # Build gen_init_cpio
    if [ ! -f build/gen_init_cpio ]; then
        gcc -o build/gen_init_cpio usr/gen_init_cpio.c
    fi

    # Compile init with docker gcc-3.3.5 (for 2.6 kernel ABI compat)
    echo "=== Compiling init ==="
    docker run {{docker_flags}} {{docker_image}} bash -c 'gcc -static -o misc/initramfs/init misc/initramfs/init.c -Os'

    # Create cpio archive
    echo "=== Creating initramfs ==="
    build/gen_init_cpio misc/initramfs/initramfs.txt | gzip > build/initramfs.cpio.gz

# Run kernel in QEMU
run: build cpio
    qemu-system-i386 \
        -kernel build/arch/i386/boot/bzImage \
        -initrd build/initramfs.cpio.gz \
        -append "console=ttyS0" \
        -nographic -no-reboot -m 256M

# Debug kernel with GDB (QEMU gdbserver on :1234, breaks at start_kernel)
debug: cpio
    #!/bin/bash
    set -eu
    cd "{{srcdir}}"
    echo "=== Starting QEMU with GDB server on :1234 ==="
    echo 'gdb build/vmlinux  -ex "target remote :1234" -ex "hb start_kernel" -ex "c"'
    echo "=== Connecting GDB ==="
    qemu-system-i386 \
        -kernel build/arch/i386/boot/bzImage \
        -initrd build/initramfs.cpio.gz \
        -append "console=ttyS0 nokaslr" \
        -nographic -no-reboot -m 256M \
        -s -S

# Clean all build artifacts
clean:
    rm -rf build
