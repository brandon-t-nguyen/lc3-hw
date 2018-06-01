test_tristate.iver: src/tristate.v test/test_tristate.v
	iverilog -o $@ $^
	vvp $@

clean:
	rm -f *.iver
	rm *.vcd

.PHONY:	all clean
