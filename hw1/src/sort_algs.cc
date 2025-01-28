#include <algorithm>
#include <omp.h>
#include "sort_algs.h"

// ------------------- Partition function (used by quicksort) -------------------
static int partitionFunc(int arr[], int low, int high) {
    int pivot = arr[high];
    int i = low - 1; 
    for (int j = low; j < high; j++) {
        if (arr[j] < pivot) {
            i++;
            std::swap(arr[i], arr[j]);
        }
    }
    std::swap(arr[i + 1], arr[high]);
    return i + 1;
}

// ------------------- Sequential Quicksort -------------------
static void quickSortSeqUtil(int arr[], int low, int high) {
    if (low < high) {
        int pi = partitionFunc(arr, low, high);
        quickSortSeqUtil(arr, low, pi - 1);
        quickSortSeqUtil(arr, pi + 1, high);
    }
}

void quickSortSeq(int arr[], int n) {
    quickSortSeqUtil(arr, 0, n - 1);
}

// ------------------- Parallel Quicksort (OpenMP) -------------------
static void parallelQuickSortUtil(int arr[], int low, int high, int depth) {
    if (low < high) {
        int pi = partitionFunc(arr, low, high);

        if (depth > 0) {
#pragma omp parallel sections
            {
#pragma omp section
                {
                    parallelQuickSortUtil(arr, low, pi - 1, depth - 1);
                }
#pragma omp section
                {
                    parallelQuickSortUtil(arr, pi + 1, high, depth - 1);
                }
            }
        } else {
            // fallback to sequential
            quickSortSeqUtil(arr, low, pi - 1);
            quickSortSeqUtil(arr, pi + 1, high);
        }
    }
}

void quickSortPar(int arr[], int n, int num_threads) {
    // approximate depth from #threads
    int depth = 0;
    while ((1 << depth) < num_threads) {
        depth++;
    }
    parallelQuickSortUtil(arr, 0, n - 1, depth);
}
