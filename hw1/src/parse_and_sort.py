import re

# File with the results
input_file = "outputs/gridsearch_results.txt"

# Read the file and collect SUMMARY lines
with open(input_file, "r") as f:
    lines = f.readlines()

# Regex to extract data from SUMMARY lines
summary_pattern = re.compile(
    r"SUMMARY: CompilerFlags=(.+?), Alg=(.+?), Threads=(\d+), AvgTimeMS=([\d\.]+), Correct=(.+)"
)

# Parse the SUMMARY lines into a structured format
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

# Sort by AvgTimeMS
sorted_results = sorted(parsed_results, key=lambda x: x["AvgTimeMS"])

# Print the top 10 fastest results
print("=========================================")
print("       Top 10 Fastest Overall           ")
print("=========================================")
for result in sorted_results[:10]:
    print(
        f"SUMMARY: CompilerFlags={result['CompilerFlags']}, "
        f"Alg={result['Algorithm']}, Threads={result['Threads']}, "
        f"AvgTimeMS={result['AvgTimeMS']:.4f}, Correct={result['Correct']}"
    )
