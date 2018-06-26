IVER_FLAGS += -Wall

test_mau.iver: test/test_mau.v src/mau.v ../common/src/*.v
	iverilog $(IVER_FLAGS) -s $(subst .iver,,$@) -o $@ $^
	vvp $@

clean:
	rm -f *.iver
	rm *.vcd

.PHONY:	all clean
