# ------------------------------------------------------------------------------

BUILDDIR := $(shell pwd)/build/$(shell hostname)
BINDIR := $(BUILDDIR)/bin
RUNDIR := $(BUILDDIR)/run
LOGDIR := $(BUILDDIR)/logs

targets := \
${BINDIR}/i2c_tb ${RUNDIR}/dump.vcd

.PHONY: all
all: $(targets)

.PHONY: clean
clean:
	rm -fv ${BINDIR}/*
	rm -fv ${RUNDIR}/*
	rm -fv ${LOGDIR}/*

# ------------------------------------------------------------------------------

${BINDIR}/i2c_tb: i2c.sv i2c_tb.sv
	mkdir -p ${BINDIR}
	iverilog -Wall -g2012 -o $@ $^

${RUNDIR}/dump.vcd: ${BINDIR}/i2c_tb
	mkdir -p ${RUNDIR} ${LOGDIR}
	cd ${RUNDIR}; ${BINDIR}/i2c_tb > ${LOGDIR}/i2c_tb.log 2>&1; cd -

# ------------------------------------------------------------------------------
