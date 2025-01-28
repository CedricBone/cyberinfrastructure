/************************************************************
 * sort_experiments.cpp
 * 
 * Usage:
 *   ./sort_experiments <algorithm> <num_threads> <input_file> <output_file>
 * 
 * Algorithms: std, quick, quick_par
 ************************************************************/
#include <cstdio>
#include <algorithm>
#include <chrono>
#include <string>
#include <omp.h>
#include "sort_algs.h"

static int* X = nullptr;

int main(int argc, char** argv) {
    if (argc < 5) {
        fprintf(stderr, "Usage: %s <algorithm> <num_threads> <input_file> <output_file>\n", argv[0]);
        return 1;
    }

    std::string alg = argv[1];
    int num_threads = std::stoi(argv[2]);
    const char* input_file = argv[3];
    const char* output_file = argv[4];

    // Read input
    FILE* fin = fopen(input_file, "r");
    if (!fin) {
        fprintf(stderr, "Error opening input file %s\n", input_file);
        return 1;
    }

    int N, K, A, B, C, M;
    fscanf(fin, "%d%d%d%d%d%d", &N, &K, &A, &B, &C, &M);

    X = new int[N];

    for(int i = 0; i < K; i++) {
        fscanf(fin, "%d", &X[i]);
    }
    fclose(fin);

    // Generate the rest
    for(int i = K; i < N; i++) {
        long long val = ((long long)A * X[i - 1] + (long long)B * X[i - 2] + C) % M;
        X[i] = (int) val;
    }

    // Time measurement
    auto start = std::chrono::high_resolution_clock::now();

    // Choose sorting algorithm
    if (alg == "std") {
        std::sort(X, X + N);
    } else if (alg == "quick") {
        quickSortSeq(X, N);
    } else if (alg == "quick_par") {
        // set number of OpenMP threads (in quickSortPar we also rely on depth)
        // but let's also set the global OMP env
        #ifdef _OPENMP
        omp_set_num_threads(num_threads);
        #endif
        quickSortPar(X, N, num_threads);
    } else {
        fprintf(stderr, "Unknown algorithm: %s\n", alg.c_str());
        delete[] X;
        return 1;
    }

    auto end = std::chrono::high_resolution_clock::now();
    double time_ms = std::chrono::duration<double, std::milli>(end - start).count();

    // Write output
    FILE* fout = fopen(output_file, "w");
    if (!fout) {
        fprintf(stderr, "Error opening output file %s\n", output_file);
        delete[] X;
        return 1;
    }
    for(int i = 0; i < N; i++) {
        fprintf(fout, "%d\n", X[i]);
    }
    fclose(fout);

    // Print summary line
    printf("Algorithm=%s, Threads=%d, InputFile=%s, TimeMS=%.4f\n",
           alg.c_str(), num_threads, input_file, time_ms);

    delete[] X;
    return 0;
}
