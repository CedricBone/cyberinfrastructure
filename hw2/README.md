# High-Performance Cosine Similarity Search with CUDA

This project implements a cosine similarity search algorithm using CUDA. The implementation efficiently finds vectors in a dataset that meet or exceed a specified similarity threshold when compared to query vectors.

## Project Structure

- `src/`
  - `best_match.cu` - CUDA implementation of the fast cosine similarity search algorithm
  - `ann.cc` - Baseline ANN implementation (provided)
  - `check_output.py` - Script to verify output accuracy against reference
  - `compare.py` - Script to compare performance between implementations
- `binaries/`
  - `best_match` - Compiled binary of fast implementation
  - `ann` - Compiled binary of the baseline implementation
- `samples/`
  - Sample input/output files for testing
- `compile.sh` - Script to compile the code
- `run.sh` - Script to run the compiled code

## Algorithm

The implementation uses a brute-force cosine similarity search with several optimizations:

1. **GPU Parallelization**: All dataset vectors are compared to the query vector in parallel using CUDA.
2. **Vectorized Memory Access**: The code processes data in chunks to optimize memory throughput.
3. **Fast Math Operations**: Using CUDA's fast math intrinsics for improved performance.
4. **Batched Processing**: When multiple queries are present, they are processed in batches for better efficiency.
5. **Fallback Logic**: If no vector meets the exact threshold, the algorithm returns the vector with highest similarity.

The core algorithm flow:
1. Load dataset vectors to GPU memory
2. For each query:
   - Calculate cosine similarity between the query and all dataset vectors
   - Find vectors with similarity ≥ target threshold
   - Return the index of the best match (or -1 if none found)

## Input Format

The input consists of multiple lines:

- **First line**: Contains 8 integers: `N D K A B C M Q`
  - `N` (1 ≤ N ≤ 1,000,000): Number of D-dimensional vectors
  - `D` (1 ≤ D ≤ 1,024): Dimensionality of each vector
  - `K, A, B, C, M` (≤ 10^9 + 7): Parameters for pseudo-random data generation
  - `Q` (1 ≤ Q ≤ 10,000): Number of queries

- **Second line**: `K` space-separated integers (0 ≤ X[i] < M), which are initial values for generating the dataset.

- **Next Q lines**: Each query contains one target similarity and one D-dimensional vector: `target_sim v1 v2 ... vD`
  - `target_sim`: Desired similarity threshold
  - `v1, v2, ..., vD` (0 ≤ vi < M): Query vector

## Output Format

For each query, output a single line containing an index (0-based) of the vector from the dataset whose cosine similarity to the query vector is at least `target_sim`. If no vector satisfies the condition, output `-1`.

## Compilation and Execution

To compile the code:
```bash
./compile.sh
```

To run the code:
```bash
./run.sh <input_file> <output_file>
```

Example:
```bash
./run.sh samples/sample1.in output.out
```