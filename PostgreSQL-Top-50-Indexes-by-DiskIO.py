import psycopg2
import time

# Connect to the database
conn = psycopg2.connect(
    host='hostname', 
    port='port', 
    user='username', 
    password='password', 
    database='database'
)

while True:
    # Execute the query to get the top 50 indexes
    cursor = conn.cursor()
    cursor.execute(
        """
        SELECT relname, idx_blks_read, idx_blks_hit
        FROM pg_statio_user_indexes
        ORDER BY idx_blks_read + idx_blks_hit DESC
        LIMIT 50
        """
    )
    rows = cursor.fetchall()
    
    # Print the results
    print("Index Name | Blocks Read | Blocks Hit")
    for row in rows:
        print("{} | {} | {}".format(row[0], row[1], row[2]))
    print("\n")
    
    # Wait for a few seconds before running the query again
    time.sleep(10)

# Close the connection
cursor.close()
conn.close()
