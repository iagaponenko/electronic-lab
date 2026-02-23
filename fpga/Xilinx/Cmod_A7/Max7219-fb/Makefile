# ------------------------------------------------------------------------------

BUILDDIR := $(shell pwd)/build/$(shell hostname)
BINDIR := $(BUILDDIR)/bin
RUNDIR := $(BUILDDIR)/run
LOGDIR := $(BUILDDIR)/logs

targets := \
${BINDIR}/debounce ${RUNDIR}/debounce.vcd \
${BINDIR}/lfsr ${RUNDIR}/lfsr.vcd \
${BINDIR}/random ${RUNDIR}/random.vcd \
${BINDIR}/spi_max7219 ${RUNDIR}/spi_max7219.vcd \
${BINDIR}/pattern_random ${RUNDIR}/pattern_random.vcd \
${BINDIR}/pattern_random1 ${RUNDIR}/pattern_random1.vcd \
${BINDIR}/pattern_conwaylife ${RUNDIR}/pattern_conwaylife.vcd \
${BINDIR}/main ${RUNDIR}/main.vcd

.PHONY: all
all: $(targets)

.PHONY: clean
clean:
	rm -fv ${BINDIR}/*
	rm -fv ${RUNDIR}/*
	rm -fv ${LOGDIR}/*

# ------------------------------------------------------------------------------
${BINDIR}/debounce: design/debounce.sv tb/debounce_tb.sv
	mkdir -p ${BINDIR}
	iverilog -Wall -g2012 -o $@ $^

${RUNDIR}/debounce.vcd: ${BINDIR}/debounce
	mkdir -p ${RUNDIR} ${LOGDIR}
	cd ${RUNDIR}; ${BINDIR}/debounce 2>&1 > ${LOGDIR}/debounce.log; cd -

# ------------------------------------------------------------------------------
${BINDIR}/lfsr: design/lfsr.sv tb/lfsr_tb.sv
	mkdir -p ${BINDIR}
	iverilog -Wall -g2012 -o $@ $^

${RUNDIR}/lfsr.vcd: ${BINDIR}/lfsr
	mkdir -p ${RUNDIR} ${LOGDIR}
	cd ${RUNDIR}; ${BINDIR}/lfsr 2>&1 > ${LOGDIR}/lfsr.log; cd -

# ------------------------------------------------------------------------------
${BINDIR}/random: design/lfsr.sv design/random.sv tb/random_tb.sv
	mkdir -p ${BINDIR}
	iverilog -Wall -g2012 -o $@ $^

${RUNDIR}/random.vcd: ${BINDIR}/random
	mkdir -p ${RUNDIR} ${LOGDIR}
	cd ${RUNDIR}; ${BINDIR}/random 2>&1 > ${LOGDIR}/random.log; cd -

# ------------------------------------------------------------------------------

${BINDIR}/spi_max7219: design/spi_max7219.sv tb/spi_max7219_tb.sv
	mkdir -p ${BINDIR}
	iverilog -Wall -g2012 -o $@ $^

${RUNDIR}/spi_max7219.vcd: ${BINDIR}/spi_max7219
	mkdir -p ${RUNDIR} ${LOGDIR}
	cd ${RUNDIR}; ${BINDIR}/spi_max7219 2>&1 > ${LOGDIR}/spi_max7219.log; cd -

# ------------------------------------------------------------------------------

${BINDIR}/pattern_random: design/lfsr.sv design/random.sv design/max7219_types.sv design/pattern_random.sv tb/pattern_random_tb.sv
	mkdir -p ${BINDIR}
	iverilog -Wall -g2012 -o $@ $^

${RUNDIR}/pattern_random.vcd: ${BINDIR}/pattern_random
	mkdir -p ${RUNDIR} ${LOGDIR}
	cd ${RUNDIR}; ${BINDIR}/pattern_random 2>&1 > ${LOGDIR}/pattern_random.log; cd -

# ------------------------------------------------------------------------------

${BINDIR}/pattern_random1: design/lfsr.sv design/random.sv design/max7219_types.sv design/pattern_random1.sv tb/pattern_random1_tb.sv
	mkdir -p ${BINDIR}
	iverilog -Wall -g2012 -o $@ $^

${RUNDIR}/pattern_random1.vcd: ${BINDIR}/pattern_random1
	mkdir -p ${RUNDIR} ${LOGDIR}
	cd ${RUNDIR}; ${BINDIR}/pattern_random1 2>&1 > ${LOGDIR}/pattern_random1.log; cd -

# ------------------------------------------------------------------------------

${BINDIR}/pattern_conwaylife: design/lfsr.sv design/random.sv design/max7219_types.sv design/pattern_conwaylife.sv tb/pattern_conwaylife_tb.sv
	mkdir -p ${BINDIR}
	iverilog -Wall -g2012 -o $@ $^

${RUNDIR}/pattern_conwaylife.vcd: ${BINDIR}/pattern_conwaylife
	mkdir -p ${RUNDIR} ${LOGDIR}
	cd ${RUNDIR}; ${BINDIR}/pattern_conwaylife 2>&1 > ${LOGDIR}/pattern_conwaylife.log; cd -

# ------------------------------------------------------------------------------

main_files := \
	design/debounce.sv \
	design/lfsr.sv \
	design/random.sv \
	design/max7219_types.sv \
	design/spi_max7219.sv \
	design/spi_max7219_driver.sv \
	design/pattern_infinite_snake.sv \
	design/pattern_finite_snake.sv \
	design/pattern_clock.sv \
	design/pattern_circles.sv \
	design/pattern_random.sv \
	design/main.sv \
	tb/main_tb.sv

${BINDIR}/main: $(main_files)
	mkdir -p ${BINDIR}
	iverilog -Wall -g2012 -o $@ $^

${RUNDIR}/main.vcd: ${BINDIR}/main
	mkdir -p ${RUNDIR} ${LOGDIR}
	cd ${RUNDIR}; ${BINDIR}/main 2>&1 > ${LOGDIR}/main.log; cd -
# ------------------------------------------------------------------------------
