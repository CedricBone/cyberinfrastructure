# Project Overview

## Directory Structure

```plaintext
./
├── README.md
├── base_hw1            # Original homework file
│   ├── compile.sh
│   ├── output_file
│   ├── run.sh
│   ├── sample1.in
│   ├── sample1.out
│   ├── sample2.in
│   ├── sample2.out
│   ├── sample3.in
│   ├── sample4.in
│   ├── sample5.in
│   ├── sample6.in
│   ├── sample7.in
│   ├── sample8.in
│   ├── sort
│   ├── sort.cc
│   └── test.sh
├── compile.sh        # final complie command 
├── outputs           # Stores test outputs
│   ├── gridsearch_results.txt
│   ├── summary_temp.txt
│   └── testout.txt
├── run.sh            # Runs sorting for a given input file
├── samples           # Test files 
│   ├── sample1.in
│   ├── sample1.out
│   ├── sample2.in
│   ├── sample2.out
│   ├── sample3.in
│   ├── sample4.in
│   ├── sample5.in
│   ├── sample6.in
│   ├── sample7.in
│   └── sample8.in
├── scripts 
│   ├── compiler.sh     # Complie script for the gridsearch
│   ├── gridsearch.sh   # gridearch script
│   └── test.sh          # run tests on the samples (removed the output files because some were too big)
└── src
    ├── parse_and_sort.py  #used for sorting gridserarch output to find best result
    ├── sort.cc            # The final optimized sorting program (parallel quicksort)
    ├── sort_algs.cc       # Implements sorting algorithms
    ├── sort_algs.h           # declerations
    └── sort_experiments.cc # Main testing program
```

---

## Steps Used to Generate Final `sort.cc`
- Run Grid Search:  
   ```bash
   bash scripts/gridsearch.sh
   ```
- Update `sort.cc` and `compile.sh` with the best configuration

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

## Prompts (to ChatGPT o1 and Deepseek-r1 14B):

### Prompt 1 – General Sorting Optimization
> I need to implement an efficient sorting program in C++. The input consists of an integer sequence, with some values provided and the rest generated using a formula. The program should use the best sorting algorithm available (either `std::sort`, quicksort, or a parallel sorting method). Additionally, I want to explore different compiler optimizations (`-O2`, `-O3`, `-march=native`) and thread configurations to determine the best performance. Can you help me design the system and automate the testing to find the optimal parameters?

### Prompt 2 – Grid Search
> I want to run a performance benchmark to determine the best sorting method for a given dataset. The options include `std::sort`, sequential quicksort, and OpenMP-based parallel quicksort. I also want to test different compiler optimizations (`-O2`, `-O3`, `-march=native`) and various thread counts. Once the best configuration is found, I will update my sorting implementation to use that configuration. Can you provide automation scripts to run and analyze the tests?

### Prompt 3 – Modular Code
> I'm working on a sorting project where I need to read a sequence of integers, generate additional values, and sort the sequence efficiently. The sorting method should be chosen dynamically based on testing. I also want to structure the project modularly, with separate files for sorting logic, execution, and automation scripts for compilation, testing, and performance tuning. Can you help design this system?

### Prompt 4 – Modular Code
> Generate more sample{n}.in files. Here is an example of one:... 

(I used the sort.cc from the original hw1 to generate the .out files)