#!/usr/bin/env bash
# best configuration = SUMMARY: CompilerFlags=-O3  -fopenmp, Alg=quick_par, Threads=2, AvgTimeMS=364.3867, Correct=OK

g++ -O3 -fopenmp -o sort src/sort.cc