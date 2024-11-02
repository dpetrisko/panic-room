
TOP := /home/petrisko/scratch/panicroom

INSTALL_DIR := $(CURDIR)/install
BUILD_DIR := $(CURDIR)/build

NEWLIB_SRC := $(TOP)/newlib
RVGCC_SRC := $(TOP)/riscv-gnu-toolchain

SPIKE_BIN := $(INSTALL_DIR)/bin/spike
LFS_DIR := $(TOP)/littlefs
LFS_DATA := $(TOP)/littlefs/lfs.h

MKLFS_BIN := $(INSTALL_DIR)/bin/riscv64-unknown-elf-dramfs-mklfs
RVGCC_BIN := $(INSTALL_DIR)/bin/riscv64-unknown-elf-gcc
RVGCC_CFLAGS := -fPIC -march=rv64gc -mabi=lp64d -mcmodel=medany
RVGCC_OBJDUMP := $(INSTALL_DIR)/bin/riscv64-unknown-elf-objdump -D
SPIKE := $(INSTALL_DIR)/bin/spike

RVGCC_MK := $(BUILD_DIR)/Makefile

%/lfs.h:
	git clone --recurse-submodules -b v2.9.3 git@github.com:littlefs-project/littlefs

%/spike:
	git clone --recurse-submodules -b v1.1.0 git@github.com:riscv/riscv-isa-sim
	cd riscv-isa-sim; ./configure --prefix=$(INSTALL_DIR)
	$(MAKE) -C riscv-isa-sim all install

%/Makefile:
	mkdir -p $(@D)
	cd $(@D); \
		$(RVGCC_SRC)/configure \
			--prefix=$(INSTALL_DIR) \
			--with-newlib-src=$(NEWLIB_SRC) \
			--disable-linux --disable-gdb --disable-qemu-system \
			--with-isa-spec=2.2 --with-arch=rv64gcb --with-abi=lp64d --with-cmodel=medany \
			--with-target-cflags="-mstrict-align" \
			--with-target-cxxflags="-mstrict-align"

%/riscv64-unknown-elf-gcc %/riscv64-unknown-elf-dramfs-mklfs: $(RVGCC_MK)
	$(MAKE) -C build \
		NEWLIB_TARGET_FLAGS_EXTRA="--enable-dramfs --with-littlefs=$(LFS_DIR)" \
		all

deps: | $(SPIKE_BIN) $(LFS_DATA)
all: | $(RVGCC_BIN) $(MKLFS_BIN)

clean:
	rm -rf riscv-isa-sim/
	rm -rf littlefs/
	rm -rf build/
	rm -rf install/

#do-test:
#	cd test; \
#		$(MKLFS) 128 64 hello.txt > lfs_mem.c; \
#		$(RVGCC) -c crt0.S lfs_mem.c bsg_dramfs_intf.c fhello.c; \
#		$(RVGCC) -nostartfiles -Tlink.ld lfs_mem.o bsg_dramfs_intf.o crt0.o fhello.o -o fhello -ldramfs; \
#		$(RVOD) fhello > fhello.dump
#		$(SPIKE) -l --isa=rv64gc fhello 2> spike.log;

