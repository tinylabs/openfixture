#!/bin/sh
#
# Wrapper around python wrapper to generate fixture with my geometry
# Only argument is .kicad_board file
#

BOARD=$1
OUTPUT="fixture-v10"

# PCB thickness
PCB=0.8
LAYER='B.Cu'
REV='rev.10'

# Nearest opposite side component to border
BORDER=0.8

# Material dimensions
MAT=2.45
SCREW_LEN=16.0
SCREW_D=3.0
WASHER_TH=1.0
NUT_TH=2.4
NUT_F2F=5.45
NUT_C2C=6.10
POGO_UNCOMPRESSED_LENGTH=16

# Call python wrapper
python GenFixture.py --board $BOARD --layer $LAYER --rev $REV --mat_th $MAT --pcb_th $PCB --out $OUTPUT --screw_len $SCREW_LEN --screw_d $SCREW_D --washer_th $WASHER_TH --nut_th $NUT_TH --nut_f2f $NUT_F2F --nut_c2c $NUT_C2C --border $BORDER --pogo-uncompressed-length $POGO_UNCOMPRESSED_LENGTH

