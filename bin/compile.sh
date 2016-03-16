#!/bin/bash

mkdir -p bin
cd matlab
mcc -m pipeline_T2.m -m ${SPM12_HOME}/spm_vol.m -m cell2num.m -m AB_t2s.m
mv pipeline_T2 ../bin
cd ..
