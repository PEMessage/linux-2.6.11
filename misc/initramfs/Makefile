INITRAMFS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PROJECT_DIR   := $(abspath $(INITRAMFS_DIR)/../..)
INIT_SRC      := $(INITRAMFS_DIR)/init.c
INIT_BIN      := $(INITRAMFS_DIR)/init
INITRAMFS_TXT := $(INITRAMFS_DIR)/initramfs.txt
GEN_INIT_CPIO := $(PROJECT_DIR)/build/gen_init_cpio
CPIO_GZ       := $(PROJECT_DIR)/build/initramfs-minimal.cpio.gz

DOCKER_IMG    := debian-sarge-builder-i386
DOCKER_VOL    := $(PROJECT_DIR):$(PROJECT_DIR)

.PHONY: all cpio clean

all: cpio

# --- compile gen_init_cpio (used to create cpio archives) ---
$(GEN_INIT_CPIO): $(PROJECT_DIR)/usr/gen_init_cpio.c
	gcc -o $@ $<

# --- compile minimal init inside Docker (gcc-3.3.5 for 2.6 ABI compat) ---
$(INIT_BIN): $(INIT_SRC)
	docker run --rm -i \
		-v $(DOCKER_VOL) \
		-w $(PROJECT_DIR) \
		$(DOCKER_IMG) bash -c 'gcc -static -o $(INIT_BIN) $(INIT_SRC) -Os'

# --- create cpio.gz from initramfs description ---
$(CPIO_GZ): $(INIT_BIN) $(INITRAMFS_TXT) $(GEN_INIT_CPIO)
	cd $(PROJECT_DIR) && $(GEN_INIT_CPIO) $(INITRAMFS_TXT) | gzip > $(CPIO_GZ)

cpio: $(CPIO_GZ)

clean:
	rm -f $(CPIO_GZ)
