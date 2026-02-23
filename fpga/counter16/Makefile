# ------------------------------------------------------------------------------

BUILDDIR := $(shell pwd)/build/$(shell hostname)
BINDIR := $(BUILDDIR)/bin
RUNDIR := $(BUILDDIR)/run
LOGDIR := $(BUILDDIR)/logs

targets := \
${BINDIR}/testbench ${RUNDIR}/dump.vcd

.PHONY: all
all: $(targets)

.PHONY: clean
clean:
	rm -fv ${BINDIR}/*
	rm -fv ${RUNDIR}/*
	rm -fv ${LOGDIR}/*

# ------------------------------------------------------------------------------

${BINDIR}/testbench: counter16.sv testbench.sv
	mkdir -p ${BINDIR}
	iverilog -Wall -g2012 -o $@ $^

${RUNDIR}/dump.vcd: ${BINDIR}/testbench
	mkdir -p ${RUNDIR} ${LOGDIR}
	cd ${RUNDIR}; ${BINDIR}/testbench > ${LOGDIR}/testbench.log 2>&1; cd -

# ------------------------------------------------------------------------------
