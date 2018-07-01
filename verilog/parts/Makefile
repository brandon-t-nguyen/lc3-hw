IVER_FLAGS += -Wall

test_23X256.iver: test/test_23X256.v src/microchip_23X256.v
	iverilog $(IVER_FLAGS) -s $(subst .iver,,$@) -o $@ $^
	vvp $@

clean:
	rm -f *.iver
	rm *.vcd

.PHONY:	all clean
