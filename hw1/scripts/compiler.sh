#!/usr/bin/env bash
# scripts/compiler.sh

CXX=${CXX:-g++}
CXXFLAGS=${CXXFLAGS:-"-O2 -fopenmp"}

echo "Compiler: $CXX"
echo "Flags:    $CXXFLAGS"

# For multi-alg approach:
$CXX $CXXFLAGS src/sort_experiments.cc src/sort_algs.cc -o src/sort_experiments

echo "Finished building 'sort_experiments'"
