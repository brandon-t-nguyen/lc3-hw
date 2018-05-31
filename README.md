# lc3-hw
Implementing Dr. Yale Patt's LC-3 ISA in Verilog.

Initially, this project will implement the LC-3 as per the microarchitecture documentation
in Introduction to Computing Systems 2e Appendix C.

The second phase will involve putting the implementation onto a Xilinx Basys3 FPGA as well
as implementing the LC-3 devices; I fear this will probably take most of the time due
to the simplified nature of the interface they expose.

## Software Dependencies
* make
* Icarus Verilog (simulation)
* Xilinx Vivado Web-Pack (FPGA implementation)

### Arch Linux
```
sudo pacman -S make iverilog
```
See <https://wiki.archlinux.org/index.php/Xilinx_Vivado> for how to get Vivado running

### Ubuntu
```
sudo apt install build-essential iverilog
```
See <https://www.xilinx.com/support/download.html> for the Vivado Web-Pack download .

## Hardware Dependencies
* Digilent Basys 3 Artix-7 FPGA Trainer board (this will be the only FPGA I will be testing this on)
