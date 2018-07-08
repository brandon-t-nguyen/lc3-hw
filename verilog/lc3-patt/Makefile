IVER_FLAGS += -Wall

test_mau.iver: test/test_mau.v src/mau.v ../common/src/*.v
	iverilog $(IVER_FLAGS) -s $(subst .iver,,$@) -o $@ $^
	vvp $@

test_mem_microchip.iver: test/test_mem_microchip.v src/mem_microchip.v ../common/src/*.v ../parts/src/microchip_23X256.v
	iverilog $(IVER_FLAGS) -s $(subst .iver,,$@) -o $@ $^
	vvp $@

test_cpu.iver: test/test_cpu.v src/cpu.v ../common/src/*.v
	iverilog $(IVER_FLAGS) -s $(subst .iver,,$@) -o $@ $^
	vvp $@

clean:
	rm -f *.iver
	rm *.vcd

.PHONY:	all clean
