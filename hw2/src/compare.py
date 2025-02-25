#!/usr/bin/env python3
import os
import subprocess
import time
import re

# Paths to executables and files
BASELINE_EXE = "binaries/ann"           # baseline ANN executable
HNSW_EXE     = "binaries/best_match"  # our new dynamic HNSW executable
CHECK_SCRIPT = "src/check_output.py"        # accuracy checker
SAMPLES_DIR  = "samples"                # directory containing .in and reference .out files

def run_cmd(cmd):
    start = time.perf_counter()
    proc = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    elapsed = time.perf_counter() - start
    return elapsed, proc.stdout, proc.stderr, proc.returncode

def parse_accuracy(output):
    m = re.search(r"Accuracy:\s*([\d.]+)%\s*\((\d+)/(\d+)\s+lines\s+match\)", output)
    if m:
        return float(m.group(1)), int(m.group(2)), int(m.group(3))
    return 0.0, 0, 0

def compare_executables(sample):
    in_file = os.path.join(SAMPLES_DIR, sample)
    ref_out = in_file.replace(".in", ".out")
    baseline_tmp = in_file + ".baseline.out"
    hnsw_tmp = in_file + ".hnsw.out"
    
    print(f"Processing {sample}...")
    # Run baseline
    cmd_base = f"{BASELINE_EXE} \"{in_file}\" \"{baseline_tmp}\""
    base_time, base_out, base_err, base_rc = run_cmd(cmd_base)
    if base_rc != 0:
        print(f"Baseline error on {sample}: {base_err}")
        return
    cmd_check = f"python3 {CHECK_SCRIPT} \"{baseline_tmp}\" \"{ref_out}\""
    _, check_base, _, _ = run_cmd(cmd_check)
    base_acc, base_corr, base_tot = parse_accuracy(check_base)
    
    # Run HNSW dynamic
    cmd_hnsw = f"{HNSW_EXE} \"{in_file}\" \"{hnsw_tmp}\""
    hnsw_time, hnsw_out, hnsw_err, hnsw_rc = run_cmd(cmd_hnsw)
    if hnsw_rc != 0:
        print(f"HNSW error on {sample}: {hnsw_err}")
        return
    cmd_check2 = f"python3 {CHECK_SCRIPT} \"{hnsw_tmp}\" \"{ref_out}\""
    _, check_hnsw, _, _ = run_cmd(cmd_check2)
    hnsw_acc, hnsw_corr, hnsw_tot = parse_accuracy(check_hnsw)
    
    # Clean up temporary output files
    os.remove(baseline_tmp)
    os.remove(hnsw_tmp)
    
    print(f"{sample} results:")
    print(f"  Baseline: time={base_time:.3f}s, accuracy={base_acc:.2f}% ({base_corr}/{base_tot})")
    print(f"  HNSW:     time={hnsw_time:.3f}s, accuracy={hnsw_acc:.2f}% ({hnsw_corr}/{hnsw_tot})")
    print("")

def main():
    samples = sorted([f for f in os.listdir(SAMPLES_DIR) if f.endswith(".in")])
    for sample in samples:
        compare_executables(sample)

if __name__ == "__main__":
    main()
