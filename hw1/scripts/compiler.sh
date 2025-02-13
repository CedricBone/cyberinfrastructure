#!/usr/bin/env bash
# scripts/compiler.sh for the grid search

CXX=${CXX:-g++}
CXXFLAGS=${CXXFLAGS:-"-O2 -fopenmp"}

echo "Compiler: $CXX"
echo "Flags:    $CXXFLAGS"

$CXX $CXXFLAGS src/sort_experiments.cc src/sort_algs.cc -o src/sort_experiments

echo "Finished building 'sort_experiments'"
