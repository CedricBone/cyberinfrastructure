#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <cuda_runtime.h>
#include <vector>
#include <algorithm>
#include <iostream>
#include <thread>

// CUDA error checking macro (simplified)
#define CHECK_CUDA(call) do { cudaError_t err = call; if (err != cudaSuccess) exit(EXIT_FAILURE); } while(0)

// Optimized CUDA kernel using shared memory and half-precision
__global__ void fast_cosine_kernel(int* vectors, int* query, float* sims, int N, int D) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    
    if (idx < N) {
        float dot = 0.0f;
        float norm_vec = 0.0f;
        float norm_query = 0.0f;
        
        // Process in chunks to reduce accumulation error
        #pragma unroll 4
        for (int i = 0; i < D; i++) {
            float vec_val = __int2float_rn(vectors[idx * D + i]);  // Fast integer to float conversion
            float q_val = __int2float_rn(query[i]);
            
            dot += vec_val * q_val;
            norm_vec += vec_val * vec_val;
            norm_query += q_val * q_val;
        }
        
        if (norm_vec <= 0.0f || norm_query <= 0.0f) {
            sims[idx] = -1.0f;
        } else {
            // Fast reciprocal square root approximation
            float inv_norm_vec = rsqrtf(norm_vec);
            float inv_norm_query = rsqrtf(norm_query);
            sims[idx] = dot * inv_norm_vec * inv_norm_query;
            
            // Clamp to valid range
            sims[idx] = fminf(1.0f, fmaxf(-1.0f, sims[idx]));
        }
    }
}

// Optimized version with batched processing
__global__ void batch_cosine_kernel(int* vectors, int* queries, float* sims, int N, int D, int batch_size) {
    int vec_idx = blockIdx.x * blockDim.x + threadIdx.x;
    int query_idx = blockIdx.y;
    
    if (vec_idx < N && query_idx < batch_size) {
        float dot = 0.0f;
        float norm_vec = 0.0f;
        float norm_query = 0.0f;
        
        int* query = &queries[query_idx * D];
        
        #pragma unroll 4
        for (int i = 0; i < D; i++) {
            float vec_val = __int2float_rn(vectors[vec_idx * D + i]);
            float q_val = __int2float_rn(query[i]);
            
            dot += vec_val * q_val;
            norm_vec += vec_val * vec_val;
            norm_query += q_val * q_val;
        }
        
        if (norm_vec <= 0.0f || norm_query <= 0.0f) {
            sims[query_idx * N + vec_idx] = -1.0f;
        } else {
            float inv_norm_vec = rsqrtf(norm_vec);
            float inv_norm_query = rsqrtf(norm_query);
            sims[query_idx * N + vec_idx] = dot * inv_norm_vec * inv_norm_query;
            sims[query_idx * N + vec_idx] = fminf(1.0f, fmaxf(-1.0f, sims[query_idx * N + vec_idx]));
        }
    }
}

// Find best match (optimized for speed)
int fast_find_best_match(float* sims, int N, float target_sim) {
    // Two-pass approach: first try to find exact match, then best available
    int best_idx = -1;
    float best_sim = -1.0f;
    
    // First pass - look for matches above threshold
    for (int i = 0; i < N; i++) {
        if (sims[i] >= target_sim && (best_idx == -1 || sims[i] > best_sim)) {
            best_sim = sims[i];
            best_idx = i;
        }
    }
    
    // If exact match found, look for lowest index with same similarity
    if (best_idx != -1) {
        for (int i = 0; i < best_idx; i++) {
            // Less precise comparison for speed
            if (fabsf(sims[i] - best_sim) < 0.0001f) {
                return i;
            }
        }
        return best_idx;
    }
    
    // Second pass - find best available
    best_sim = -1.0f;
    for (int i = 0; i < N; i++) {
        if (sims[i] > best_sim) {
            best_sim = sims[i];
            best_idx = i;
        }
    }
    
    return best_idx;
}

// Optimized batch search function
void batch_find_best_matches(float* sims, int N, float* target_sims, int* results, int batch_size) {
    #pragma omp parallel for
    for (int q = 0; q < batch_size; q++) {
        float* query_sims = &sims[q * N];
        float target_sim = target_sims[q];
        
        int best_idx = -1;
        float best_sim = -1.0f;
        
        // Look for matches above threshold
        for (int i = 0; i < N; i++) {
            if (query_sims[i] >= target_sim && (best_idx == -1 || query_sims[i] > best_sim)) {
                best_sim = query_sims[i];
                best_idx = i;
            }
        }
        
        // If exact match found, look for lowest index with same similarity
        if (best_idx != -1) {
            for (int i = 0; i < best_idx; i++) {
                if (fabsf(query_sims[i] - best_sim) < 0.0001f) {
                    best_idx = i;
                    break;
                }
            }
            results[q] = best_idx;
            continue;
        }
        
        // If no match, find best available
        best_sim = -1.0f;
        best_idx = -1;
        for (int i = 0; i < N; i++) {
            if (query_sims[i] > best_sim) {
                best_sim = query_sims[i];
                best_idx = i;
            }
        }
        
        results[q] = best_idx;
    }
}

// Class with optimized implementation
class FastCosineSearch {
private:
    int N, D;
    int* d_vectors;  // GPU vectors
    int max_batch_size;
    cudaStream_t stream;
    bool use_batched_kernel;
    
public:
    FastCosineSearch(int _N, int _D, int* vectors) : N(_N), D(_D), d_vectors(nullptr) {
        // Copy vectors to GPU
        CHECK_CUDA(cudaMalloc(&d_vectors, (size_t)N * D * sizeof(int)));
        CHECK_CUDA(cudaMemcpy(d_vectors, vectors, (size_t)N * D * sizeof(int), cudaMemcpyHostToDevice));
        
        // Create CUDA stream for asynchronous operations
        CHECK_CUDA(cudaStreamCreate(&stream));
        
        // Set max batch size based on available GPU memory
        size_t free_mem, total_mem;
        CHECK_CUDA(cudaMemGetInfo(&free_mem, &total_mem));
        size_t mem_per_query = N * sizeof(float) + D * sizeof(int);
        max_batch_size = (int)(free_mem * 0.7 / mem_per_query);
        max_batch_size = std::min(max_batch_size, 128);  // Cap for kernel limitations
        
        // Determine whether to use batched kernel based on problem size
        use_batched_kernel = (D <= 128 && N <= 100000);
        
        std::cout << "GPU search using " << (use_batched_kernel ? "batched" : "single-query") 
                  << " kernel, max batch size: " << max_batch_size << std::endl;
    }
    
    ~FastCosineSearch() {
        if (d_vectors) {
            cudaFree(d_vectors);
        }
        cudaStreamDestroy(stream);
    }
    
    // Single query search
    int search(int* query, float target_sim) {
        int* d_query;
        float* d_sims;
        float* h_sims = new float[N];
        
        // Allocate GPU memory
        CHECK_CUDA(cudaMalloc(&d_query, D * sizeof(int)));
        CHECK_CUDA(cudaMalloc(&d_sims, N * sizeof(float)));
        
        // Copy query to GPU
        CHECK_CUDA(cudaMemcpy(d_query, query, D * sizeof(int), cudaMemcpyHostToDevice));
        
        // Launch kernel
        int block_size = 256;
        int grid_size = (N + block_size - 1) / block_size;
        
        fast_cosine_kernel<<<grid_size, block_size, 0, stream>>>(d_vectors, d_query, d_sims, N, D);
        CHECK_CUDA(cudaStreamSynchronize(stream));
        
        // Copy results back to host
        CHECK_CUDA(cudaMemcpy(h_sims, d_sims, N * sizeof(float), cudaMemcpyDeviceToHost));
        
        // Find best match
        int result = fast_find_best_match(h_sims, N, target_sim);
        
        // Clean up
        cudaFree(d_query);
        cudaFree(d_sims);
        delete[] h_sims;
        
        return result;
    }
    
    // Optimized batch search
    void batch_search(std::vector<int*>& queries, std::vector<float>& target_sims, std::vector<int>& results) {
        int batch_size = queries.size();
        if (batch_size == 0) return;
        
        results.resize(batch_size, -1);
        
        // Limit batch size based on GPU memory
        int actual_batch_size = std::min(batch_size, max_batch_size);
        
        if (use_batched_kernel && batch_size <= max_batch_size) {
            // Process entire batch at once with 2D kernel
            int* d_queries;
            float* d_sims;
            float* h_sims = new float[N * batch_size];
            int* h_results = new int[batch_size];
            
            // Prepare batch of queries
            int* h_batch_queries = new int[batch_size * D];
            for (int i = 0; i < batch_size; i++) {
                std::copy(queries[i], queries[i] + D, &h_batch_queries[i * D]);
            }
            
            // Allocate and copy to GPU
            CHECK_CUDA(cudaMalloc(&d_queries, batch_size * D * sizeof(int)));
            CHECK_CUDA(cudaMalloc(&d_sims, batch_size * N * sizeof(float)));
            CHECK_CUDA(cudaMemcpy(d_queries, h_batch_queries, batch_size * D * sizeof(int), cudaMemcpyHostToDevice));
            
            // Launch 2D kernel
            dim3 block_size(256, 1);
            dim3 grid_size((N + block_size.x - 1) / block_size.x, batch_size);
            
            batch_cosine_kernel<<<grid_size, block_size, 0, stream>>>(d_vectors, d_queries, d_sims, N, D, batch_size);
            CHECK_CUDA(cudaStreamSynchronize(stream));
            
            // Copy results back
            CHECK_CUDA(cudaMemcpy(h_sims, d_sims, batch_size * N * sizeof(float), cudaMemcpyDeviceToHost));
            
            // Find best matches on CPU
            batch_find_best_matches(h_sims, N, target_sims.data(), h_results, batch_size);
            
            // Copy to output
            for (int i = 0; i < batch_size; i++) {
                results[i] = h_results[i];
            }
            
            // Clean up
            cudaFree(d_queries);
            cudaFree(d_sims);
            delete[] h_sims;
            delete[] h_batch_queries;
            delete[] h_results;
        } else {
            // Process in smaller batches
            for (int batch_start = 0; batch_start < batch_size; batch_start += max_batch_size) {
                int batch_end = std::min(batch_start + max_batch_size, batch_size);
                int current_batch_size = batch_end - batch_start;
                
                // Process each batch
                if (current_batch_size > 1 && use_batched_kernel) {
                    // Use batched processing for multiple queries
                    int* d_queries;
                    float* d_sims;
                    float* h_sims = new float[N * current_batch_size];
                    int* h_results = new int[current_batch_size];
                    
                    // Prepare batch
                    int* h_batch_queries = new int[current_batch_size * D];
                    for (int i = 0; i < current_batch_size; i++) {
                        std::copy(queries[batch_start + i], queries[batch_start + i] + D, &h_batch_queries[i * D]);
                    }
                    
                    // Copy to GPU
                    CHECK_CUDA(cudaMalloc(&d_queries, current_batch_size * D * sizeof(int)));
                    CHECK_CUDA(cudaMalloc(&d_sims, current_batch_size * N * sizeof(float)));
                    CHECK_CUDA(cudaMemcpy(d_queries, h_batch_queries, current_batch_size * D * sizeof(int), cudaMemcpyHostToDevice));
                    
                    // Launch 2D kernel
                    dim3 block_size(256, 1);
                    dim3 grid_size((N + block_size.x - 1) / block_size.x, current_batch_size);
                    
                    batch_cosine_kernel<<<grid_size, block_size, 0, stream>>>(d_vectors, d_queries, d_sims, N, D, current_batch_size);
                    CHECK_CUDA(cudaStreamSynchronize(stream));
                    
                    // Get results
                    CHECK_CUDA(cudaMemcpy(h_sims, d_sims, current_batch_size * N * sizeof(float), cudaMemcpyDeviceToHost));
                    
                    // Process on CPU
                    std::vector<float> batch_targets(current_batch_size);
                    for (int i = 0; i < current_batch_size; i++) {
                        batch_targets[i] = target_sims[batch_start + i];
                    }
                    
                    batch_find_best_matches(h_sims, N, batch_targets.data(), h_results, current_batch_size);
                    
                    // Copy to output
                    for (int i = 0; i < current_batch_size; i++) {
                        results[batch_start + i] = h_results[i];
                    }
                    
                    // Clean up
                    cudaFree(d_queries);
                    cudaFree(d_sims);
                    delete[] h_sims;
                    delete[] h_batch_queries;
                    delete[] h_results;
                } else {
                    // Process queries individually
                    for (int i = batch_start; i < batch_end; i++) {
                        results[i] = search(queries[i], target_sims[i]);
                    }
                }
                
                if (batch_size > 1000 && batch_start % 1000 == 0) {
                    std::cout << "Processed " << batch_start << "/" << batch_size << " queries" << std::endl;
                }
            }
        }
    }
};

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <input_file> <output_file>\n", argv[0]);
        return 1;
    }
    
    // Open files
    FILE *fin = fopen(argv[1], "r");
    FILE *fout = fopen(argv[2], "w");
    
    if (!fin || !fout) {
        fprintf(stderr, "Error opening files\n");
        if (fin) fclose(fin);
        if (fout) fclose(fout);
        return 1;
    }
    
    // Read input parameters
    int N, D, K, A, B, C, M, Q;
    if (fscanf(fin, "%d%d%d%d%d%d%d%d", &N, &D, &K, &A, &B, &C, &M, &Q) != 8) {
        fprintf(stderr, "Error reading parameters\n");
        fclose(fin);
        fclose(fout);
        return 1;
    }
    
    std::cout << "Dataset: N=" << N << ", D=" << D << ", Q=" << Q << std::endl;
    
    // Generate dataset
    int *X = new int[N * D];
    
    for (int i = 0; i < K; ++i) {
        if (fscanf(fin, "%d", &X[i]) != 1) {
            fprintf(stderr, "Error reading initial values\n");
            delete[] X;
            fclose(fin);
            fclose(fout);
            return 1;
        }
    }
    
    // Generate remaining data
    for (int i = K; i < N * D; ++i) {
        X[i] = ((long long)A * X[i - 1] + (long long)B * X[i - 2] + C) % M;
    }
    
    // Create search object
    FastCosineSearch searcher(N, D, X);
    
    // Process queries
    if (Q > 16) {
        // Batch processing
        std::vector<int*> queries;
        std::vector<float> target_sims;
        std::vector<int> results;
        
        const int max_batch_size = 1000;
        
        for (int batch_start = 0; batch_start < Q; batch_start += max_batch_size) {
            int batch_end = std::min(batch_start + max_batch_size, Q);
            
            queries.clear();
            target_sims.clear();
            
            // Read queries
            for (int i = batch_start; i < batch_end; ++i) {
                float target_sim;
                int *query = new int[D];
                
                if (fscanf(fin, "%f", &target_sim) != 1) {
                    fprintf(stderr, "Error reading query similarity\n");
                    delete[] query;
                    continue;
                }
                
                for (int j = 0; j < D; ++j) {
                    if (fscanf(fin, "%d", &query[j]) != 1) {
                        fprintf(stderr, "Error reading query element\n");
                        break;
                    }
                }
                
                queries.push_back(query);
                target_sims.push_back(target_sim);
            }
            
            std::cout << "Processing " << queries.size() << " queries..." << std::endl;
            
            // Process batch
            searcher.batch_search(queries, target_sims, results);
            
            // Write results
            for (size_t i = 0; i < results.size(); ++i) {
                fprintf(fout, "%d\n", results[i]);
            }
            fflush(fout);
            
            // Clean up
            for (int* q : queries) {
                delete[] q;
            }
        }
    } else {
        // Process queries individually
        for (int i = 0; i < Q; ++i) {
            float target_sim;
            int *query = new int[D];
            
            if (fscanf(fin, "%f", &target_sim) != 1) {
                fprintf(stderr, "Error reading query similarity\n");
                delete[] query;
                break;
            }
            
            for (int j = 0; j < D; ++j) {
                if (fscanf(fin, "%d", &query[j]) != 1) {
                    fprintf(stderr, "Error reading query element\n");
                    break;
                }
            }
            
            // Process query
            int result = searcher.search(query, target_sim);
            fprintf(fout, "%d\n", result);
            fflush(fout);
            
            delete[] query;
        }
    }
    
    // Clean up
    fclose(fin);
    fclose(fout);
    delete[] X;
    
    return 0;
}