BUSYBOX_VERSION := 1.00
BUSYBOX_GIT     := https://git.busybox.net/busybox
BUSYBOX_TAG     := 1_00

BUSYBOX_DIR     := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PROJECT_DIR     := $(abspath $(BUSYBOX_DIR)/../..)
SRC_DIR         := $(BUSYBOX_DIR)/src
BIN             := $(SRC_DIR)/busybox
INITRAMFS_TXT   := $(BUSYBOX_DIR)/initramfs/initramfs.txt
GEN_INIT_CPIO   := $(PROJECT_DIR)/build/gen_init_cpio
CPIO_GZ         := $(PROJECT_DIR)/build/initramfs-busybox.cpio.gz

DOCKER_IMG      := debian-sarge-builder-i386
DOCKER_VOL      := $(PROJECT_DIR):$(PROJECT_DIR)

.PHONY: all busybox cpio clean distclean y

all: cpio

# --- clone busybox source (git tag 1_00 ~= busybox 1.00) ---
$(SRC_DIR)/Makefile:
	git clone --depth 1 --branch $(BUSYBOX_TAG) $(BUSYBOX_GIT) $(SRC_DIR)

# --- compile gen_init_cpio (used to create cpio archives) ---
$(GEN_INIT_CPIO): $(PROJECT_DIR)/usr/gen_init_cpio.c
	gcc -o $@ $<

# --- compile busybox inside Docker (gcc-3.3.5 for 2.6 ABI compat) ---
$(BIN): $(SRC_DIR)/Makefile
	docker run --rm -i \
		-v $(DOCKER_VOL) \
		-w $(SRC_DIR) \
		$(DOCKER_IMG) bash -c \
		'if [ ! -f .config ]; then \
			make defconfig > /dev/null 2>&1; \
			sed -i "s/# CONFIG_STATIC is not set/CONFIG_STATIC=y/" .config; \
		fi; \
		make -j4 2>&1' | grep -v "^: warning:"

busybox: $(BIN)

# --- create cpio.gz from initramfs description ---
$(CPIO_GZ): $(BIN) $(INITRAMFS_TXT) $(GEN_INIT_CPIO)
	cd $(PROJECT_DIR) && $(GEN_INIT_CPIO) $(INITRAMFS_TXT) | gzip > $(CPIO_GZ)

cpio: $(CPIO_GZ)

# --- clean ---
clean:
	rm -f $(CPIO_GZ)

distclean: clean
	rm -rf $(SRC_DIR)
	rm -f $(GEN_INIT_CPIO)
