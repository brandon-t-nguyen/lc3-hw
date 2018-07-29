#!/bin/bash
# lc3hex2readmemh.sh <input hex files for image...>

for file in $@
do
    printf '@' && head -n 1 $file
    tail -n +2 $file
done
