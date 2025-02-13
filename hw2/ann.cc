#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <limits.h>
#include <omp.h>

int N, D, K, A, B, C, M, Q;
int *X;

double cosine_similarity(int *x, int *y, int D) {
  double dot = 0, norm_x = 0, norm_y = 0;
  for (int i = 0; i < D; ++i) {
    dot += (long long)x[i] * y[i];
    norm_x += (long long)x[i] * x[i];
    norm_y += (long long)y[i] * y[i];
  }
  if (norm_x == 0 || norm_y == 0) {
    return -1;
  }
  return dot / (sqrt(norm_x) * sqrt(norm_y));
}

int find_nearest(int *query, double target_sim) {
  double max_sim = -2;
  int max_id = -1;

  for (int i = 0; i < N; ++i) {
    double sim = cosine_similarity(query, X + i * D, D);
    if (sim > max_sim) {
      max_sim = sim;
      max_id = i;
    }
  }
  return max_id;
}

int main(int argc, char **argv) {
  FILE *fin = fopen(argv[1], "r");
  FILE *fout = fopen(argv[2], "w");

  fscanf(fin, "%d%d%d%d%d%d%d%d", &N, &D, &K, &A, &B, &C, &M, &Q);
  X = new int[N * D];

  for (int i = 0; i < K; ++i)
    fscanf(fin, "%d", &X[i]);

  for (int i = K; i < N * D; ++i)
    X[i] = ((long long)A * X[i - 1] + (long long)B * X[i - 2] + C) % M;

  float *queries = new float[(D + 1) * Q];
  int *results = new int[Q];

  for (int i = 0; i < Q; ++i) {
    fscanf(fin, "%f", &queries[i * (D + 1)]);
    for (int j = 0; j < D; ++j)
      fscanf(fin, "%d", (int*)&queries[i * (D + 1) + 1 + j]);
  }

  for (int i = 0; i < Q; ++i)
    results[i] = find_nearest((int*)&queries[i * (D + 1) + 1], queries[i * (D + 1)]);

  for (int i = 0; i < Q; ++i)
    fprintf(fout, "%d\n", results[i]);

  fclose(fin);
  fclose(fout);
  delete[] X;
  delete[] queries;
  delete[] results;

  return 0;
}

