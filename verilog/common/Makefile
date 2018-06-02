test_tristate_buffer.iver: src/tristate_buffer.v test/test_tristate_buffer.v
	iverilog -o $@ $^
	vvp $@

test_register.iver: src/register.v test/test_register.v
	iverilog -o $@ $^
	vvp $@

#test_ram.iver: src/ram.v test/test_ram.v
#	iverilog -o $@ $^
#	vvp $@

test_spram.iver: src/ram.v test/test_ram.v
	iverilog -s test_spram -o $@ $^
	vvp $@

test_dpram.iver: src/ram.v test/test_ram.v
	iverilog -s test_dpram -o $@ $^
	vvp $@


clean:
	rm -f *.iver
	rm *.vcd

.PHONY:	all clean
