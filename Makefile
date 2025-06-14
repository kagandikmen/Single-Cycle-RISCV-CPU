# V-FRONT Main Makefile
# Created:		2025-05-25
# Modified:		2025-06-02
# Author:		Kagan Dikmen

include ut/rv32ui/Makefrag
include ut/v-front/Makefrag

TESTDIRS := ut/rv32ui ut/v-front

TESTS := $(rv32ui_sc_tests) $(v-front_tests)

FAILING_TESTS :=

PASSING_TESTS := $(filter-out $(FAILING_TESTS), $(TESTS))

DESIGN_SOURCES := \
	rtl/cpu.v

SIMULATION_SOURCES := \
	sim/cpu_tb.v

MODE ?=

RISCV_PREFIX ?= riscv32-unknown-elf

CFLAGS += -march=rv32i_zicsr_zifencei -Wall -Wextra -Os -fomit-frame-pointer \
	-ffreestanding -fno-builtin -fanalyzer -std=gnu99 \
	-Wall -Werror=implicit-function-declaration -ffunction-sections -fdata-sections
LDFLAGS += -march=rv32i_zicsr_zifencei -nostartfiles \
	-Wl,-m,elf32lriscv --specs=nosys.specs -Wl,--no-relax -Wl,--gc-sections \
	-Wl,-Tsw/v-front.ld

all: clean run_iverilog

vivado: clean run_vivado

create_project:
	rm -rf v-front.prj
	for source in $(DESIGN_SOURCES) $(SIMULATION_SOURCES); do \
		echo "verilog work $$source" >> v-front.prj; \
	done

copy_tests: create_project
	test -d tests || mkdir tests
	for testdir in $(TESTDIRS); do \
		for test in $$(ls $$testdir | grep .S); do \
			cp $$testdir/$$test tests; \
		done \
	done

compile_tests: copy_tests
	test -d tests-build || mkdir tests-build
	$(RISCV_PREFIX)-gcc -c $(CFLAGS) -o sw/mtvec_handler.o sw/mtvec_handler.S
	for test in tests/* ; do \
		test=$${test##*/}; test=$${test%.*}; \
		$(RISCV_PREFIX)-gcc -c $(CFLAGS) -Iut -Iut/rv32ui -o tests-build/$$test.o tests/$$test.S; \
		$(RISCV_PREFIX)-gcc -o tests-build/$$test.elf $(LDFLAGS) tests-build/$$test.o sw/mtvec_handler.o; \
		$(RISCV_PREFIX)-objcopy -j .text -j .data -j .rodata -O binary tests-build/$$test.elf tests-build/$$test.bin; \
		hexdump -v -e '1/4 "%08x\n"' tests-build/$$test.bin > tests-build/$$test.hex; \
	done

run_vivado: compile_tests
	for test in $(PASSING_TESTS) ; do \
		printf "Running test %-15s\t" "$$test:"; \
		TOHOST_ADDR=$$($(RISCV_PREFIX)-nm -n tests-build/$$test.elf | gawk '$$3=="tohost" { printf "%d\n", strtonum("0x"$$1) }'); \
		xelab cpu_tb -relax -debug all \
			-generic_top MEM_INIT_FILE=\"tests-build/$$test.hex\" \
			-generic_top TOHOST_ADDR=$$TOHOST_ADDR \
			-prj v-front.prj > /dev/null; \
		xsim cpu_tb -R --onfinish quit > tests-build/$$test.results; \
		RESULT=$$(cat tests-build/$$test.results | gawk '/Note:/ {print}' | sed 's/Note://' | gawk '/Success|Failure/ {print}'); \
		echo "$$RESULT"; \
		if [ "$(MODE)" = "ci" ] || [ "$(MODE)" = "CI" ]; then \
			if echo "$$RESULT" | grep -q 'Failure'; then \
				echo "Test $$test failed!"; \
				exit 1; \
			fi; \
		fi; \
	done

run_iverilog: compile_tests
	for test in $(PASSING_TESTS) ; do \
		printf "Running test %-15s\t" "$$test:"; \
		TOHOST_ADDR=$$($(RISCV_PREFIX)-nm -n tests-build/$$test.elf | gawk '$$3=="tohost" { printf "%d\n", strtonum("0x"$$1) }'); \
		iverilog -o tests-build/$$test.out \
			-Irtl/ -Isim/ -Irtl/luftALU/rtl/ -Irtl/luftALU/rtl/subunits/ \
			-Pcpu_tb.MEM_INIT_FILE=\"tests-build/$$test.hex\" \
			-Pcpu_tb.TOHOST_ADDR=$$TOHOST_ADDR \
			sim/cpu_tb.v; \
		vvp tests-build/$$test.out > tests-build/$$test.results; \
		RESULT=$$(cat tests-build/$$test.results | gawk '/Note:/ {print}' | sed 's/Note://' | gawk '/Success|Failure/ {print}'); \
		echo "$$RESULT"; \
		if [ "$(MODE)" = "ci" ] || [ "$(MODE)" = "CI" ]; then \
			if echo "$$RESULT" | grep -q 'Failure'; then \
				echo "Test $$test failed!"; \
				exit 1; \
			fi; \
		fi; \
	done

clean:
	rm -rf tests-build/ webtalk* xelab* xsim* .Xil/ *.wdb vivado_pid* *.jou vivado*.log

clean_all: clean
	rm -rf v-front.prj sw/mtvec_handler.o tests/ sim/*.hex
