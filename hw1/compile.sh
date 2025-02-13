#!/usr/bin/env bash
# best configuration = SUMMARY: CompilerFlags=-O3 -march=native -fopenmp, Alg=quick_par, Threads=4, AvgTimeMS=347.6451, Correct=OK

g++ -O3 -march=native -fopenmp -o sort src/sort.cc