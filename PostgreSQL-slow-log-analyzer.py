import re

log_file = "path/to/postgresql-slow.log"
source_data = {}

# Extract information from log file
with open(log_file, "r") as f:
    for line in f:
        if "duration:" in line:
            # Extract source, query text, latency, and count
            match = re.search(r"\[(\w+)\] ([\w\s]+) duration: ([\d\.]+) ms statement: (.+)", line)
            source = match.group(1)
            query = match.group(4)
            latency = float(match.group(3))
            count = source_data.get(source, {"queries": {}})
            query_data = count["queries"].get(query, {"latency": 0, "count": 0})
            query_data["latency"] += latency
            query_data["count"] += 1
            count["queries"][query] = query_data
            source_data[source] = count

# Print information for each source
for source, data in source_data.items():
    print("Source:", source)
    for query, query_data in data["queries"].items():
        print("  Query Text:", query)
        print("  Latency:", query_data["latency"], "ms")
        print("  Number of executions:", query_data["count"])
    print("")
