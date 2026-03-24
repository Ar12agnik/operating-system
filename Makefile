.PHONY: build run clean help

build:
	./scripts/build-os.sh

run:
	qemu-system-x86_64 \
	  -m 1024 \
	  -drive file=build/os.img,format=raw \
	  -nographic \
	  -serial mon:stdio

clean:
	sudo rm -rf build

help:
	@echo "Targets:"
	@echo "  make build  - Build a minimal Linux-based OS disk image"
	@echo "  make run    - Run the disk image in QEMU"
	@echo "  make clean  - Remove build artifacts"
