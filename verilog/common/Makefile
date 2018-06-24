IVER_FLAGS += -Wall
test_tristate_buffer.iver: src/tristate_buffer.v test/test_tristate_buffer.v
	iverilog $(IVER_FLAGS) -s $(subst .iver,,$@) -o $@ $^
	vvp $@

test_register.iver: src/register.v test/test_register.v
	iverilog $(IVER_FLAGS) -s $(subst .iver,,$@) -o $@ $^
	vvp $@

test_spram.iver: src/ram.v test/test_ram.v
	iverilog $(IVER_FLAGS) -s $(subst .iver,,$@) -o $@ $^
	vvp $@

test_dpram.iver: src/ram.v test/test_ram.v
	iverilog $(IVER_FLAGS) -s $(subst .iver,,$@) -o $@ $^
	vvp $@

test_rom.iver: src/rom.v test/test_rom.v
	iverilog $(IVER_FLAGS) -s $(subst .iver,,$@) -o $@ $^
	vvp $@

clean:
	rm -f *.iver
	rm *.vcd

.PHONY:	all clean
