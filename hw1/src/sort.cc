#include <stdio.h>
#include <algorithm>
#include<string.h>
#include <omp.h>

//static int X[10000000]; 

// Partition function used by quicksort
static int partition(int arr[], int low, int high) {
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

// Parallel QuickSort function
static void quickSortParallel(int arr[], int low, int high, int depth) {
    if (low < high) {
        int pivot = partition(arr, low, high);

        if (depth > 0) {
            #pragma omp parallel sections
            {
                #pragma omp section
                {
                    quickSortParallel(arr, low, pivot - 1, depth - 1);
                }
                #pragma omp section
                {
                    quickSortParallel(arr, pivot + 1, high, depth - 1);
                }
            }
        } else {
            // If max depth reached, fall back to sequential
            std::sort(arr + low, arr + high + 1);
        }
    }
}

// Wrapper function for parallel quicksort
void quickSortPar(int arr[], int n, int num_threads) {
    omp_set_num_threads(num_threads); // Set number of OpenMP threads
    int depth = 0;
    while ((1 << depth) < num_threads) depth++; // Calculate recursion depth
    quickSortParallel(arr, 0, n - 1, depth);
}

int main(int argc, char** argv) {
    int N, K, A, B, C, M;
    FILE* fin = fopen(argv[1], "r");
    fscanf(fin, "%d%d%d%d%d%d", &N, &K, &A, &B, &C, &M);
	int* X = new int[N];
    for (int i = 0; i < K; ++i) {
        fscanf(fin, "%d", &X[i]);
    }
    fclose(fin);

    for (int i = K; i < N; ++i) {
        X[i] = ((long long)A * X[i - 1] + (long long)B * X[i - 2] + C) % M;
    }

    // arallel quicksort - number of threads = 2
    quickSortPar(X, N, 2);

    FILE* fout = fopen(argv[2], "w");
    for (int i = 0; i < N; ++i) {
        fprintf(fout, "%d\n", X[i]);
    }
    fclose(fout);

    return 0;
}


/*
#include<stdio.h>
#include<string.h>
#include<algorithm>

//int X[10000000];

int main(int argc,char** argv){
	int N,K,A,B,C,M;
	FILE* fin = fopen(argv[1],"r");
	fscanf(fin,"%d%d%d%d%d%d",&N,&K,&A,&B,&C,&M);
	int* X = new int[N];
	for(int i = 0;i < K;++i)
		fscanf(fin,"%d",&X[i]);
	fclose(fin);

	FILE* fout = fopen(argv[2],"w");
	for(int i = K;i < N;++i)
		X[i] = ((long long)A * X[i - 1] + (long long)B * X[i - 2] + C) % M;
	std::sort(X,X + N);
	for(int i = 0;i < N;++i)
		fprintf(fout,"%d\n",X[i]);
	fclose(fout);
	return 0;
}
*/

