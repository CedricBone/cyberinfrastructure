# Approximate Nearest Neighbor Search – Grid Search Suite

This project contains three approximate nearest neighbor (ANN) search implementations using CUDA and multi-threading:
- **LSH (Locality-Sensitive Hashing)**
- **HNSW (Hierarchical Navigable Small World Graph)**
- **VQ (Vector Quantization)**

Each algorithm is implemented in its own CUDA source file (compiled with NVCC) and uses preprocessor macros for key hyperparameters.

## File Structure

```
./
├── README.md
├── samples
│   ├── sample1.in
│   ├── sample1.out
│   ├── sample2.in
│   └── sample2.out
├── scripts
│   ├── Miniconda3-latest-Linux-x86_64.sh
│   ├── compile.sh
│   └── run.sh
└── src
    ├── ann.cc
    ├── check_output.py
    ├── gridsearch.py
    ├── hnsw.cu
    ├── lsh.cu
    └── vq.cu
```


## Algorithm Implementations

### LSH (Locality-Sensitive Hashing)
- **Source:** `src/lsh.cu`
- **Key Hyperparameters:**
  - `L_NUM_HYPERPLANES`: Number of hyperplanes (default 32)
  - `THREADS_PER_BLOCK`: CUDA kernel block size (default 256)
- **Overview:**  
  Precomputes LSH hashes for dataset vectors using random hyperplanes (in parallel with threads) and then uses a CUDA kernel to check candidate buckets for each query.

### HNSW (Hierarchical Navigable Small World Graph)
- **Source:** `src/hnsw.cu`
- **Key Hyperparameters:**
  - `HNSW_NUM_NEIGHBORS`: Number of neighbors per vector (default 10)
  - `HNSW_NUM_RESTARTS`: Number of random restarts in greedy search (default 5)
  - `THREADS_PER_BLOCK`: (Included for consistency; default 256)
- **Overview:**  
  Builds a neighbor graph (using multi-threading) by assigning each dataset vector random neighbors and then performs a greedy search (with multiple restarts) on the graph to locate an approximate nearest neighbor.

### VQ (Vector Quantization)
- **Source:** `src/vq.cu`
- **Key Hyperparameters:**
  - `VQ_NUM_CLUSTERS`: Number of clusters for partitioning (default 20)
  - `THREADS_PER_BLOCK`: CUDA kernel block size (default 256)
- **Overview:**  
  Partitions the dataset into clusters (using round-robin assignment) and computes cluster centers. For each query, the best cluster is selected based on center similarity, and a CUDA kernel is used to scan that cluster for a candidate.

## Grid Search & Evaluation Scripts

### gridsearch.py
This script performs a grid search over hyperparameter combinations for all three algorithms. For each algorithm, it:
- Compiles the CUDA source file with different combinations of hyperparameters (using `-D` flags).
- Runs the resulting executable on all sample input files (located in `samples/`).
- Measures total runtime and computes accuracy by comparing the output with expected outputs.
- Logs all results into `gridsearch_results.txt` and identifies the best configuration (fastest with at least 60% accuracy) per algorithm and overall.

**Usage:**
```bash
chmod +x gridsearch.py
./gridsearch.py


