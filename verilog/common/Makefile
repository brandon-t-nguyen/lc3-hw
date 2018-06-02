test_tristate_buffer.iver: src/tristate_buffer.v test/test_tristate_buffer.v
	iverilog -o $@ $^
	vvp $@

test_register.iver: src/register.v test/test_register.v
	iverilog -o $@ $^
	vvp $@

clean:
	rm -f *.iver
	rm *.vcd

.PHONY:	all clean
