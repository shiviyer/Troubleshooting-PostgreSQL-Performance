import re

log_file = "path/to/postgresql-slow.log"
query_data = {}

# Extract information from log file
with open(log_file, "r") as f:
    for line in f:
        if "duration:" in line:
            # Extract source, query text, latency, and count
            match = re.search(r"\[(\w+)\] ([\w\s]+) duration: ([\d\.]+) ms statement: (.+)", line)
            source = match.group(1)
            query = match.group(4)
            latency = float(match.group(3))
            count = query_data.get(query, {"source": source, "latency": 0, "count": 0})
            count["latency"] += latency
            count["count"] += 1
            query_data[query] = count

# Print information for each query
for query, data in query_data.items():
    print("Source:", data["source"])
    print("Query Text:", query)
    print("Latency:", data["latency"], "ms")
    print("Number of executions:", data["count"])
    print("")
