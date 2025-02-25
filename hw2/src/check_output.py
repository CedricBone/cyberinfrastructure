#!/usr/bin/env python3
import sys
import itertools

def compare_files(file1, file2):
    with open(file1, "r") as f1:
        lines1 = f1.read().splitlines()
    with open(file2, "r") as f2:
        lines2 = f2.read().splitlines()
    correct = 0
    total = max(len(lines1), len(lines2))
    for l1, l2 in itertools.zip_longest(lines1, lines2, fillvalue=""):
        if l1.strip() == l2.strip():
            correct += 1
    return correct, total

def main():
    if len(sys.argv) != 3:
        print("Usage: check_output.py <output_file> <expected_output_file>")
        sys.exit(1)
    output_file = sys.argv[1]
    expected_file = sys.argv[2]
    correct, total = compare_files(output_file, expected_file)
    accuracy = (correct / total) * 100 if total > 0 else 0
    print(f"Accuracy: {accuracy:.2f}% ({correct}/{total} lines match)")
    if accuracy >= 60:
        print("PASS: Output meets the accuracy threshold.")
    else:
        print("FAIL: Output accuracy below threshold.")

if __name__ == "__main__":
    main()
