#!/bin/bash
nvcc -std=c++14 -arch=sm_61 -o binaries/best_match src/best_match.cu -Xcompiler "-fopenmp -lgomp" -Wno-deprecated-gpu-targets

# g++ ann.cc -o ann
