# Linux 2.6.11.12 (i386) Project Guide

## Build

All builds run inside a Docker container (Debian Sarge, gcc-3.3.5) via `debian-sarge-builder-i386.sh`.

```bash
just build   # defconfig + required Kconfig + make
```

Required Kconfigs automatically enabled: `SERIAL_8250_CONSOLE`, `BLK_DEV_RAM`, `BLK_DEV_INITRD`, `DEBUG_KERNEL`, `DEBUG_INFO`.

Output: `build/arch/i386/boot/bzImage`

## compile_commands.json

```bash
python3 gen_compile_commands.py -d build -o compile_commands.json
```

Uses official kernel script. `.clangd` strips incompatible GCC flags.

## Run / Debug

```bash
just run      # boot in QEMU, serial console
just debug    # QEMU with gdbserver :1234, breaks at start_kernel
```

Initramfs is built from `scripts/initramfs/init.c` (minimal static init, compiled in Docker for 2.6 ABI compat).

## Key constraints

- Userspace binaries for initramfs **must** be compiled with Docker's gcc-3.3.5; host GCC 11 produces ELFs with features (GNU_STACK) that 2.6.11 rejects.
- `-nostdinc` and gcc internal `-isystem` paths in compile commands are Docker-internal; `.clangd` handles them.
- Out-of-tree build: `O=build`, ARCH=i386.
