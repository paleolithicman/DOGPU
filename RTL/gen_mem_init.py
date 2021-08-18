#!/usr/bin/env python3

import sys
import random
import struct
import binascii
import math

SIZE = 2**18
MODES = ['zero', 'count_int', 'count_float', 'rand_float', 'rand_low_float', 'fft']
FFT_SIZE = 32768
LG_FFT_SIZE = 15

def usage():
    print('Generates 2^18 rows of 32-bit hex for memory initialization' )
    print(''                                                            )
    print('Usage: {} <mode> [filename]'.format(sys.argv[0])             )
    print('       {} <-h|--help>'      .format(sys.argv[0])             )
    print(                                                              )
    print('    mode:'                                                   )
    print('            zero             all zeros'                      )
    print('            count_int        increasing integers [1, 2^18]'  )
    print('            rand_float       random floats [-100000, 100000]')
    print('            rand_low_float   random floats [-5, 5]'          )
    exit()

# parse args
if len(sys.argv) < 2 or len(sys.argv) > 3:
    usage()

if len(sys.argv) == 2 and (sys.argv[1] == '-h' or sys.argv[1] == '--help'):
    usage()

mode = sys.argv[1]
filename = sys.argv[2] if len(sys.argv) == 3 else 'init_mem.mif'

if mode not in MODES:
    print('error: {} is not a valid mode'.format(mode))
    print()
    usage()

# generate
with open(filename, 'w') as file:
    if mode == 'zero':
        for i in range(SIZE):
           file.write('{:08X}\n'.format(0x00000000))
    elif mode == 'count_int':
        for i in range(SIZE):
            file.write('{:08X}\n'.format(i+1))
    elif mode == 'count_float':
        for i in range(SIZE):
            num_bytes = struct.pack('>f', i)
            num_str = binascii.hexlify(num_bytes).decode().upper()
            file.write('{}\n'.format(num_str))
    elif mode == 'rand_float':
        for i in range(SIZE):
            while True:
                num = random.uniform(-100000, 100000)
                if abs(num) > 1.e-5:
                    break
            num_bytes = struct.pack('>f', num)
            num_str = binascii.hexlify(num_bytes).decode().upper()
            file.write('{}\n'.format(num_str))
    elif mode == 'rand_low_float':
        for i in range(SIZE):
            while True:
                num = random.uniform(-5, 5)
                if abs(num) > 1.e-5:
                    break
            num_bytes = struct.pack('>f', num)
            num_str = binascii.hexlify(num_bytes).decode().upper()
            file.write('{}\n'.format(num_str))
    elif mode == 'fft':
        for i in range(FFT_SIZE):
            num_bytes = struct.pack('>f', i)
            num_str = binascii.hexlify(num_bytes).decode().upper()
            file.write('{}\n'.format(num_str))
            file.write('{}\n'.format("00000000"))
        for i in range(FFT_SIZE/2):
            num = math.cos(i*math.pi/FFT_SIZE)
            num_bytes = struct.pack('>f', num)
            num_str = binascii.hexlify(num_bytes).decode().upper()
            file.write('{}\n'.format(num_str))
            num = math.sin(i*math.pi/FFT_SIZE)
            num_bytes = struct.pack('>f', num)
            num_str = binascii.hexlify(num_bytes).decode().upper()
            file.write('{}\n'.format(num_str))
        for i in range(SIZE-FFT_SIZE*2-FFT_SIZE):
            file.write('{}\n'.format("00000000"))
