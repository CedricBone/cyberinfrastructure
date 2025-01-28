# Project Overview

## Directory Structure

```plaintext
hw1
├── outputs/            # Stores test outputs
│   └── testout.txt     # Example output file
├── run.sh              # Runs sorting for a given input file
├── samples/            # Stores input and expected output files
│   ├── sample1.in
│   ├── sample1.out
│   ├── sample2.in
│   └── sample2.out
├── scripts/            # Contains automation scripts
│   ├── compile.sh      # Compiles the program
│   ├── gridsearch.sh   # Runs grid search tests for optimization
│   ├── test.sh         # Compares program output with expected results
└── src/                # Contains C++ source code
    ├── sort.cc         # The final optimized sorting program
    ├── sort_algs.cc    # Implements sorting algorithms
    ├── sort_algs.h     # Sorting function declarations
    └── sort_experiments.cc # Main testing program
```

---

## Steps Used to Generate Final `sort.cc`
- Run Grid Search:  
   ```bash
   bash scripts/gridsearch.sh
   ```
- Check Best Configuration:  
   ```bash
   tail -n 10 gridsearch_results.txt
   ```
- Update `sort.cc` with the best configuration

---

## Profiling with `perf`
- Recompile with Debug Info  
   ```bash
   CXXFLAGS="-O2 -g -fopenmp" bash scripts/compiler.sh
   ```
- Record Performance Data 
   ```bash
   perf record -- ./sort samples/sample1.in outputs/perf_output.txt
   ```
- View `perf` Report  
   ```bash
   perf report
   ```
---

## Sources / Documentation

- **Documentation**: [cppreference.com – std::sort](https://en.cppreference.com/w/cpp/algorithm/sort)
- **Implementation Guide**: [GeeksForGeeks – QuickSort](https://www.geeksforgeeks.org/quick-sort/)
- **Parallel Quicksort Explanation**: [Parallel Quicksort](https://www.geeksforgeeks.org/implementation-of-quick-sort-using-mpi-omp-and-posix-thread/)
- **Tutorial**: [Bash Scripting Tutorial](https://www.freecodecamp.org/news/bash-scripting-tutorial-linux-shell-script-and-command-line-for-beginners/#heading-introduction)
- **GCC Docs**: [GCC Optimization Options](https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html)
- **OpenMP Specification**: [OpenMP API Docs](https://www.openmp.org/specifications/)
- **perf Documentation**: [perf](https://perfwiki.github.io/main/tutorial/)

---

## Prompts That Could Plausibly Lead to This Code

### Prompt 1 – General Sorting Optimization
> I need to implement an efficient sorting program in C++. The input consists of an integer sequence, with some values provided and the rest generated using a formula. The program should use the best sorting algorithm available (either `std::sort`, quicksort, or a parallel sorting method). Additionally, I want to explore different compiler optimizations (`-O2`, `-O3`, `-march=native`) and thread configurations to determine the best performance. Can you help me design the system and automate the testing to find the optimal parameters?

### Prompt 2 – Grid Search for Sorting Performance
> I want to run a performance benchmark to determine the best sorting method for a given dataset. The options include `std::sort`, sequential quicksort, and OpenMP-based parallel quicksort. I also want to test different compiler optimizations (`-O2`, `-O3`, `-march=native`) and various thread counts. Once the best configuration is found, I will update my sorting implementation to use that configuration. Can you provide the full implementation along with automation scripts to run and analyze the tests?

### Prompt 3 – Modular Sorting Code with Scripts
> I'm working on a sorting project where I need to read a sequence of integers, generate additional values, and sort the sequence efficiently. The sorting method should be chosen dynamically based on testing. I also want to structure the project modularly, with separate files for sorting logic, execution, and automation scripts for compilation, testing, and performance tuning. Can you help design and implement this system?