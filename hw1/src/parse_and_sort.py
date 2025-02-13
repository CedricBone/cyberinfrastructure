import re

input_file = "outputs/gridsearch_results.txt"
with open(input_file, "r") as f:
    lines = f.readlines()

# Extract from SUMMARY
summary_pattern = re.compile(
    r"SUMMARY: CompilerFlags=(.+?), Alg=(.+?), Threads=(\d+), AvgTimeMS=([\d\.]+), Correct=(.+)"
)
parsed_results = []
for line in lines:
    match = summary_pattern.search(line)
    if match:
        compiler_flags = match.group(1)
        algorithm = match.group(2)
        threads = int(match.group(3))
        avg_time_ms = float(match.group(4))
        correctness = match.group(5)
        parsed_results.append(
            {
                "CompilerFlags": compiler_flags,
                "Algorithm": algorithm,
                "Threads": threads,
                "AvgTimeMS": avg_time_ms,
                "Correct": correctness,
            }
        )

# Sort
sorted_results = sorted(parsed_results, key=lambda x: x["AvgTimeMS"])
print("=========================================")
print("       Top 10 Fastest Overall           ")
print("=========================================")
for result in sorted_results[:10]:
    print(
        f"SUMMARY: CompilerFlags={result['CompilerFlags']}, "
        f"Alg={result['Algorithm']}, Threads={result['Threads']}, "
        f"AvgTimeMS={result['AvgTimeMS']:.4f}, Correct={result['Correct']}"
    )
