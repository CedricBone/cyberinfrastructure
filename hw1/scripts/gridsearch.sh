#!/usr/bin/env bash
# gridsearch.sh

#################### CONFIG ####################
ALGS=("std" "quick" "quick_par")
OPT_FLAGS=("-O2" "-O3")
MARCH_FLAGS=("" "-march=native")
THREADS_LIST=("1" "2" "4" "8")

INPUT_FILES=("samples/sample1.in" "samples/sample2.in" "samples/sample3.in" "samples/sample4.in" "samples/sample5.in" "samples/sample6.in" "samples/sample7.in" "samples/sample8.in")
OUTPUT_FILES=("samples/sample1.out" "samples/sample2.out" "samples/sample3.out" "samples/sample4.out" "samples/sample5.out" "samples/sample6.out" "samples/sample7.out" "samples/sample8.out")

RESULT_FILE="outputs/gridsearch_results.txt"
SUMMARY_TEMP="outputs/summary_temp.txt"

rm -f "$RESULT_FILE" "$SUMMARY_TEMP"
touch "$RESULT_FILE" "$SUMMARY_TEMP"

# Clean old build
rm -f sort_experiments *.o

########################################
# Build, Run, Collect results
########################################
for opt in "${OPT_FLAGS[@]}"; do
  for march in "${MARCH_FLAGS[@]}"; do
    
    BUILD_FLAGS="$opt $march -fopenmp"
    echo "=========================================" | tee -a "$RESULT_FILE"
    echo "Compiling with flags: $BUILD_FLAGS" | tee -a "$RESULT_FILE"
    echo "=========================================" | tee -a "$RESULT_FILE"

    # Compile using our compiler.sh, but override FLAGS
    FLAGS="$BUILD_FLAGS" bash scripts/compiler.sh

    for alg in "${ALGS[@]}"; do
      for th in "${THREADS_LIST[@]}"; do
        sum_time=0
        correct_count=0
        num_samples=${#INPUT_FILES[@]}

        echo "----------------------------------------" | tee -a "$RESULT_FILE"
        echo "Algorithm=$alg, Threads=$th" | tee -a "$RESULT_FILE"
        echo "----------------------------------------" | tee -a "$RESULT_FILE"

        for i in "${!INPUT_FILES[@]}"; do
          in_file="${INPUT_FILES[$i]}"
          out_file="${OUTPUT_FILES[$i]}"
          tmp_output="tmp_${alg}_${th}_${i}.out"

          CMD="src/sort_experiments $alg $th $in_file $tmp_output"
          echo "COMMAND: $CMD" | tee -a "$RESULT_FILE"
          run_output=$($CMD)

          # parse time
          time_ms=$(echo "$run_output" | sed -n 's/.*TimeMS=\([0-9\.]*\).*/\1/p')
          sum_time=$(echo "$sum_time + $time_ms" | bc)

          # check correctness
          diff -qEwB "$tmp_output" "$out_file" >/dev/null
          if [ $? -eq 0 ]; then
            correct_count=$((correct_count + 1))
          fi

          echo "Result for $in_file:" | tee -a "$RESULT_FILE"
          echo "$run_output" | tee -a "$RESULT_FILE"

          rm -f "$tmp_output"
        done

        avg_time=$(echo "scale=4; $sum_time / $num_samples" | bc)
        if [ $correct_count -eq $num_samples ]; then
          correctness="OK"
        else
          correctness="FAIL($correct_count/$num_samples)"
        fi

        summary_line="SUMMARY: CompilerFlags=$BUILD_FLAGS, Alg=$alg, Threads=$th, AvgTimeMS=$avg_time, Correct=$correctness"
        echo "$summary_line" | tee -a "$RESULT_FILE"
        echo "" | tee -a "$RESULT_FILE"

        # store for final sorting
        echo "$summary_line" >> "$SUMMARY_TEMP"

      done  # end thread loop
    done    # end alg loop

  done      # end march flags
done        # end opt flags

########################################
# Top 10 fastest
########################################
echo "" | tee -a "$RESULT_FILE"
echo "=========================================" | tee -a "$RESULT_FILE"
echo "       Top 10 Fastest Overall           " | tee -a "$RESULT_FILE"
echo "=========================================" | tee -a "$RESULT_FILE"

python3 src/parse_and_sort.py | tee -a "$RESULT_FILE"

echo "Grid search complete. See '$RESULT_FILE' for details."
