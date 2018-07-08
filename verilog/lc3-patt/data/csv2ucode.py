#!/bin/python3
import sys
import csv

if len(sys.argv) < 3:
    print("csv2ucode.py <csv path> <ucode output path>")
    exit(1)

csv_path = sys.argv[1]
ucode_path = sys.argv[2]

if (csv_path == ucode_path):
    print("input and output paths are the same")
    exit(2)

num_cols = 49
num_rows = 64
start_col = 1;
start_row = 1;

with open(csv_path, "r") as f:
    reader = csv.reader(f)
    data = list(reader)
    with open(ucode_path, "w") as u:
        for row in data[start_row:start_row + num_rows - 1 + 1]:
            uinst = ""
            for cell in row[start_col:start_col + num_cols - 1 + 1]:
                if cell == " ":
                    uinst += "0"
                else:
                    uinst += cell
            u.write(uinst + "\n")
