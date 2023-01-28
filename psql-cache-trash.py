import psycopg2

# Connect to the PostgreSQL database
conn = psycopg2.connect(
    host="your_host",
    port="your_port",
    user="your_user",
    password="your_password",
    dbname="your_dbname"
)

# Create a cursor
cur = conn.cursor()

# Retrieve information from the pg_stat_bgwriter view
cur.execute("SELECT * FROM pg_stat_bgwriter")
bgwriter_data = cur.fetchone()

# Retrieve information from the pg_stat_database view
cur.execute("SELECT * FROM pg_stat_database")
db_data = cur.fetchall()

# Print the background writer data
print("Background Writer Data:")
print("Checkpoints Timed: ", bgwriter_data[0])
print("Checkpoints Requested: ", bgwriter_data[1])
print("Buffers Checkpoint: ", bgwriter_data[2])
print("Buffers Clean: ", bgwriter_data[3])
print("Maxwritten Clean: ", bgwriter_data[4])
print("Buffers Backend: ", bgwriter_data[5])
print("Buffers Alloc: ", bgwriter_data[6])

# Print the database data
print("\nDatabase Data:")
for row in db_data:
    print("Database Name: ", row[0])
    print("Buffers Checkpoint: ", row[9])
    print("Buffers Backend: ", row[10])
    print("Buffers Alloc: ", row[11])
    print("\n")

# Close the cursor and connection
cur.close()
conn.close()
