# ------------------------------------------------------------------------------

targets := \
bin/tm1638 run/tm1638.vcd \
bin/tm1638_driver run/tm1638_driver.vcd \
bin/spi_fifo run/spi_fifo.vcd \
bin/spi run/spi.vcd \
bin/fifo run/fifo.vcd \
bin/debounce run/debounce.vcd \
bin/pulse run/pulse.vcd \
bin/encoder run/encoder.vcd \
bin/max7219 run/max7219.vcd \
bin/spi_max7219 run/spi_max7219.vcd \
bin/max7219_driver run/max7219_driver.vcd

.PHONY: all
all: $(targets)

.PHONY: clean
clean:
	for target in $(targets); do rm -f $${target}; done
	rm -f logs/*.log

# ------------------------------------------------------------------------------

bin/fifo: design/fifo.sv tb/fifo_tb.sv
	mkdir -p bin
	iverilog -Wall -g2012 -o $@ $^

run/fifo.vcd: bin/fifo
	mkdir -p run logs
	cd run; ../bin/fifo >& ../logs/fifo.log; cd -

# ------------------------------------------------------------------------------

bin/spi: design/spi.sv tb/spi_tb.sv
	mkdir -p bin
	iverilog -Wall -g2012 -o $@ $^

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
	iverilog -Wall -g2012 -o $@ $^

run/spi_fifo.vcd: bin/spi_fifo
	mkdir -p run logs
	cd run; ../bin/spi_fifo >& ../logs/spi_fifo.log; cd -

# ------------------------------------------------------------------------------
bin/debounce: design/debounce.sv tb/debounce_tb.sv
	mkdir -p bin
	iverilog -Wall -g2012 -o $@ $^

run/debounce.vcd: bin/debounce
	mkdir -p run logs
	cd run; ../bin/debounce >& ../logs/debounce.log; cd -

# ------------------------------------------------------------------------------
bin/pulse: design/pulse.sv tb/pulse_tb.sv
	mkdir -p bin
	iverilog -Wall -g2012 -o $@ $^

run/pulse.vcd: bin/pulse
	mkdir -p run logs
	cd run; ../bin/pulse >& ../logs/pulse.log; cd -

# ------------------------------------------------------------------------------
bin/encoder: design/encoder.sv design/pulse.sv tb/encoder_tb.sv
	mkdir -p bin
	iverilog -Wall -g2012 -o $@ $^

run/encoder.vcd: bin/encoder
	mkdir -p run logs
	cd run; ../bin/encoder >& ../logs/encoder.log; cd -

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

bin/tm1638_driver: $(tm1638_driver_files) tb/tm1638_driver_tb.sv
	mkdir -p bin
	iverilog -Wall -g2012 -o $@ $^

run/tm1638_driver.vcd: bin/tm1638_driver
	mkdir -p run logs
	cd run; ../bin/tm1638_driver >& ../logs/tm1638_driver.log; cd -

# ------------------------------------------------------------------------------

bin/max7219: design/max7219_write.sv tb/max7219_tb.sv
	mkdir -p bin
	iverilog -Wall -g2012 -o $@ $^

run/max7219.vcd: bin/max7219
	mkdir -p run logs
	cd run; ../bin/max7219 >& ../logs/max7219.log; cd -

# ------------------------------------------------------------------------------

bin/spi_max7219: design/spi_max7219.sv tb/spi_max7219_tb.sv
	mkdir -p bin
	iverilog -Wall -g2012 -o $@ $^

run/spi_max7219.vcd: bin/spi_max7219
	mkdir -p run logs
	cd run; ../bin/spi_max7219 >& ../logs/spi_max7219.log; cd -

# ------------------------------------------------------------------------------

bin/max7219_driver: design/spi_max7219.sv design/max7219_driver.sv tb/max7219_driver_tb.sv
	mkdir -p bin
	iverilog -Wall -g2012 -o $@ $^

run/max7219_driver.vcd: bin/max7219_driver
	mkdir -p run logs
	cd run; ../bin/max7219_driver >& ../logs/max7219_driver.log; cd -

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

bin/tm1638: $(tm1638_files)
	mkdir -p bin
	iverilog -Wall -g2012 -o $@ $^

run/tm1638.vcd: bin/tm1638
	mkdir -p run logs
	cd run; ../bin/tm1638 >& ../logs/tm1638.log; cd -

# ------------------------------------------------------------------------------
