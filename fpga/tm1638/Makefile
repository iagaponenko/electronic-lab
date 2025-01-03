# ------------------------------------------------------------------------------

targets := \
bin/tm1638 run/tm1638.vcd \
bin/tm1638_driver run/tm1638_driver.vcd \
bin/spi_fifo run/spi_fifo.vcd \
bin/spi run/spi.vcd \
bin/fifo run/fifo.vcd \
bin/debounce run/debounce.vcd \
bin/pulse run/pulse.vcd

.PHONY: all
all: $(targets)

.PHONY: clean
clean:
	for target in $(targets); do rm -f $${target}; done
	rm -f logs/*.log

# ------------------------------------------------------------------------------

bin/fifo: design/fifo.sv tb/fifo_tb.sv
	mkdir -p bin
	iverilog -DSIMULATION  -Wall -g2012 -o $@ $^

run/fifo.vcd: bin/fifo
	mkdir -p run logs
	cd run; ../bin/fifo >& ../logs/fifo.log; cd -

# ------------------------------------------------------------------------------

bin/spi: design/spi.sv tb/spi_tb.sv
	mkdir -p bin
	iverilog -DSIMULATION  -Wall -g2012 -o $@ $^

run/spi.vcd: bin/spi
	mkdir -p run logs
	cd run; ../bin/spi >& ../logs/spi.log; cd -

# ------------------------------------------------------------------------------

spi_fifo_files := \
	design/spi.sv \
	design/fifo.sv \
	design/spi_fifo.sv

bin/spi_fifo: $(spi_fifo_files) tb/spi_fifo_tb.sv
	mkdir -p bin
	iverilog -DSIMULATION  -Wall -g2012 -o $@ $^

run/spi_fifo.vcd: bin/spi_fifo
	mkdir -p run logs
	cd run; ../bin/spi_fifo >& ../logs/spi_fifo.log; cd -

# ------------------------------------------------------------------------------
bin/debounce: design/debounce.sv tb/debounce_tb.sv
	mkdir -p bin
	iverilog -DSIMULATION  -Wall -g2012 -o $@ $^

run/debounce.vcd: bin/debounce
	mkdir -p run logs
	cd run; ../bin/debounce >& ../logs/debounce.log; cd -

# ------------------------------------------------------------------------------
bin/pulse: design/pulse.sv tb/pulse_tb.sv
	mkdir -p bin
	iverilog -DSIMULATION  -Wall -g2012 -o $@ $^

run/pulse.vcd: bin/pulse
	mkdir -p run logs
	cd run; ../bin/pulse >& ../logs/pulse.log; cd -

# ------------------------------------------------------------------------------

tm1638_driver_files := \
	design/tm1638_types.sv \
	design/tm1638_driver_types.sv \
	design/tm1638_driver.sv \
	design/tm1638_stimulus.sv \
	design/tm1638_stimulus_fixed.sv \
	design/tm1638_stimulus_keys.sv

bin/tm1638_driver: $(tm1638_driver_files) tb/tm1638_driver_tb.sv
	mkdir -p bin
	iverilog -DSIMULATION  -Wall -g2012 -o $@ $^

run/tm1638_driver.vcd: bin/tm1638_driver
	mkdir -p run logs
	cd run; ../bin/tm1638_driver >& ../logs/tm1638_driver.log; cd -

# ------------------------------------------------------------------------------

bin/tm1638: $(tm1638_driver_files) $(spi_fifo_files) design/debounce.sv design/pulse.sv design/tm1638.sv tb/tm1638_tb.sv
	mkdir -p bin
	iverilog -DSIMULATION -Wall -g2012 -o $@ $^

run/tm1638.vcd: bin/tm1638
	mkdir -p run logs
	cd run; ../bin/tm1638 >& ../logs/tm1638.log; cd -

# ------------------------------------------------------------------------------
