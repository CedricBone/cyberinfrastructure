#ifndef SORT_ALGS_H
#define SORT_ALGS_H

// Declaration for sequential quicksort
void quickSortSeq(int arr[], int n);

// Declaration for parallel quicksort (OpenMP)
void quickSortPar(int arr[], int n, int num_threads);

#endif
