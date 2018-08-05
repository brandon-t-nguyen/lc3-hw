#!/bin/zsh
~/projects/lccc/bin/lccc-as test.asm -o test.obj --hex
../data/lc3hex2readmemh.sh test.hex > ../data/test.img
rm test.obj test.hex
