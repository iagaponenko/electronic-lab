# ------------------------------------------------------------------------------

BUILDDIR := $(shell pwd)/build/$(shell hostname)
BINDIR := $(BUILDDIR)/bin
RUNDIR := $(BUILDDIR)/run
LOGDIR := $(BUILDDIR)/logs

targets := \
${BINDIR}/tm1638 ${RUNDIR}/tm1638.vcd \
${BINDIR}/tm1638_driver ${RUNDIR}/tm1638_driver.vcd \
${BINDIR}/spi_fifo ${RUNDIR}/spi_fifo.vcd \
${BINDIR}/spi ${RUNDIR}/spi.vcd \
${BINDIR}/fifo ${RUNDIR}/fifo.vcd \
${BINDIR}/debounce ${RUNDIR}/debounce.vcd \
${BINDIR}/pulse ${RUNDIR}/pulse.vcd \
${BINDIR}/encoder ${RUNDIR}/encoder.vcd \
${BINDIR}/max7219 ${RUNDIR}/max7219.vcd \
${BINDIR}/spi_max7219 ${RUNDIR}/spi_max7219.vcd \
${BINDIR}/max7219_driver ${RUNDIR}/max7219_driver.vcd

.PHONY: all
all: $(targets)

.PHONY: clean
clean:
	rm -fv ${BINDIR}/*
	rm -fv ${RUNDIR}/*
	rm -fv ${LOGDIR}/*

# ------------------------------------------------------------------------------

${BINDIR}/fifo: design/fifo.sv tb/fifo_tb.sv
	mkdir -p ${BINDIR}
	iverilog -Wall -g2012 -o $@ $^

${RUNDIR}/fifo.vcd: ${BINDIR}/fifo
	mkdir -p ${RUNDIR} ${LOGDIR}
	cd ${RUNDIR}; ${BINDIR}/fifo 2>&1 > ${LOGDIR}/fifo.log; cd -

# ------------------------------------------------------------------------------

${BINDIR}/spi: design/spi.sv tb/spi_tb.sv
	mkdir -p ${BINDIR}
	iverilog -Wall -g2012 -o $@ $^

${RUNDIR}/spi.vcd: ${BINDIR}/spi
	mkdir -p ${RUNDIR} ${LOGDIR}
	cd ${RUNDIR}; ${BINDIR}/spi 2>&1 > ${LOGDIR}/spi.log; cd -

# ------------------------------------------------------------------------------

spi_fifo_files := \
	design/spi.sv \
	design/fifo.sv \
	design/spi_fifo.sv

${BINDIR}/spi_fifo: $(spi_fifo_files) tb/spi_fifo_tb.sv
	mkdir -p ${BINDIR}
	iverilog -Wall -g2012 -o $@ $^

${RUNDIR}/spi_fifo.vcd: ${BINDIR}/spi_fifo
	mkdir -p ${RUNDIR} ${LOGDIR}
	cd ${RUNDIR}; ${BINDIR}/spi_fifo 2>&1 > ${LOGDIR}/spi_fifo.log; cd -

# ------------------------------------------------------------------------------
${BINDIR}/debounce: design/debounce.sv tb/debounce_tb.sv
	mkdir -p ${BINDIR}
	iverilog -Wall -g2012 -o $@ $^

${RUNDIR}/debounce.vcd: ${BINDIR}/debounce
	mkdir -p ${RUNDIR} ${LOGDIR}
	cd ${RUNDIR}; ${BINDIR}/debounce 2>&1 > ${LOGDIR}/debounce.log; cd -

# ------------------------------------------------------------------------------
${BINDIR}/pulse: design/pulse.sv tb/pulse_tb.sv
	mkdir -p ${BINDIR}
	iverilog -Wall -g2012 -o $@ $^

${RUNDIR}/pulse.vcd: ${BINDIR}/pulse
	mkdir -p ${RUNDIR} ${LOGDIR}
	cd ${RUNDIR}; ${BINDIR}/pulse 2>&1 > ${LOGDIR}/pulse.log; cd -

# ------------------------------------------------------------------------------
${BINDIR}/encoder: design/encoder.sv design/pulse.sv tb/encoder_tb.sv
	mkdir -p ${BINDIR}
	iverilog -Wall -g2012 -o $@ $^

${RUNDIR}/encoder.vcd: ${BINDIR}/encoder
	mkdir -p ${RUNDIR} ${LOGDIR}
	cd ${RUNDIR}; ${BINDIR}/encoder 2>&1 > ${LOGDIR}/encoder.log; cd -

# ------------------------------------------------------------------------------

tm1638_driver_files := \
	design/tm1638_types.sv \
	design/tm1638_driver_types.sv \
	design/tm1638_driver.sv \
	design/tm1638_stimulus.sv \
	design/tm1638_stimulus_fixed.sv \
	design/tm1638_stimulus_keys.sv \
	design/led7_types.sv \
	design/tm1638_stimulus_keys2cntr.sv \
	design/tm1638_stimulus_encoder.sv

${BINDIR}/tm1638_driver: $(tm1638_driver_files) tb/tm1638_driver_tb.sv
	mkdir -p ${BINDIR}
	iverilog -Wall -g2012 -o $@ $^

${RUNDIR}/tm1638_driver.vcd: ${BINDIR}/tm1638_driver
	mkdir -p ${RUNDIR} ${LOGDIR}
	cd ${RUNDIR}; ${BINDIR}/tm1638_driver 2>&1 > ${LOGDIR}/tm1638_driver.log; cd -

# ------------------------------------------------------------------------------

${BINDIR}/max7219: design/max7219_write.sv tb/max7219_tb.sv
	mkdir -p ${BINDIR}
	iverilog -Wall -g2012 -o $@ $^

${RUNDIR}/max7219.vcd: ${BINDIR}/max7219
	mkdir -p ${RUNDIR} ${LOGDIR}
	cd ${RUNDIR}; ${BINDIR}/max7219 2>&1 > ${LOGDIR}/max7219.log; cd -

# ------------------------------------------------------------------------------

${BINDIR}/spi_max7219: design/spi_max7219.sv tb/spi_max7219_tb.sv
	mkdir -p ${BINDIR}
	iverilog -Wall -g2012 -o $@ $^

${RUNDIR}/spi_max7219.vcd: ${BINDIR}/spi_max7219
	mkdir -p ${RUNDIR} ${LOGDIR}
	cd ${RUNDIR}; ${BINDIR}/spi_max7219 2>&1 > ${LOGDIR}/spi_max7219.log; cd -

# ------------------------------------------------------------------------------

${BINDIR}/max7219_driver: design/spi_max7219.sv design/max7219_driver.sv tb/max7219_driver_tb.sv
	mkdir -p ${BINDIR}
	iverilog -Wall -g2012 -o $@ $^

${RUNDIR}/max7219_driver.vcd: ${BINDIR}/max7219_driver
	mkdir -p ${RUNDIR} ${LOGDIR}
	cd ${RUNDIR}; ${BINDIR}/max7219_driver 2>&1 > ${LOGDIR}/max7219_driver.log; cd -

# ------------------------------------------------------------------------------

tm1638_files := \
	$(tm1638_driver_files) \
	$(spi_fifo_files) \
	design/max7219_driver.sv \
	design/spi_max7219.sv \
	design/debounce.sv \
	design/pulse.sv \
	design/encoder.sv \
	design/tm1638.sv \
	tb/tm1638_tb.sv

${BINDIR}/tm1638: $(tm1638_files)
	mkdir -p ${BINDIR}
	iverilog -Wall -g2012 -o $@ $^

${RUNDIR}/tm1638.vcd: ${BINDIR}/tm1638
	mkdir -p ${RUNDIR} ${LOGDIR}
	cd ${RUNDIR}; ${BINDIR}/tm1638 2>&1 > ${LOGDIR}/tm1638.log; cd -

# ------------------------------------------------------------------------------
