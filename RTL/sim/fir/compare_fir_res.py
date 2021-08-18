#!/usr/bin/env python3

import sys
import random
import struct
import binascii
import math

filter_start = 0 # set in krnl_ram.mif:17
filter_size = 480
input_start = 0 # set in krnl_ram.mif: 18
input_size = 2048
output_start = 32768 # set in krnl_ram.mif: 19
output_size = input_size - filter_size

memfilename = '../../init_mem.mif'
outfilename = '../../result_mem.mif'

# read memory initial file
memfile = open(memfilename)
content = memfile.readlines()

# read memory output file
outfile = open(outfilename)
content_out = outfile.readlines()

# convert hex string to float
taps = [0.0 for i in range(filter_size)]
inputs = [0.0 for i in range(input_size)]
outputs = [0.0 for i in range(output_size)]
for i in range(filter_start, filter_start+filter_size):
    taps[i] = struct.unpack('!f', bytes.fromhex(content[i][:-1]))[0]
for i in range(input_start, input_start+input_size):
    inputs[i] = struct.unpack('!f', bytes.fromhex(content[i][:-1]))[0]
for i in range(output_start, output_start+output_size):
    outputs[i-output_start] = struct.unpack('!f', bytes.fromhex(content_out[i][:-1]))[0]

# generate golden results
err = 0
for i in range(output_size):
    res = 0.0
    for j in range(filter_size):
        res += inputs[i+j]*taps[j]
    if (res - outputs[i])/res > 1e-5:
        err += 1
        print(f'line {i!r}: should be {res!r}, got {outputs[i]!r}')

if err > 0:
    print('FAILED!')
else:
    print('PASS!')
