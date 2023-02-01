import psycopg2
import time
import psutil

conn = psycopg2.connect(database="mydb", user="myuser", password="mypassword", host="localhost", port="5432")
cursor = conn.cursor()

while True:
    cursor.execute("SELECT * FROM pg_stat_activity")
    activities = cursor.fetchall()
    for activity in activities:
        process = psutil.Process(activity[0])
        cpu_percent = process.cpu_percent()
        memory_info = process.memory_info()
        io_counters = process.io_counters()
        query = activity[3]
        source = activity[2]
        if cpu_percent > 90:
            print("Process ID: ", activity[0])
            print("Query: ", query)
            print("Source: ", source)
            print("CPU Usage: ", cpu_percent)
            print("Memory Usage: ", memory_info.rss)
            print("Disk I/O: ", io_counters.read_bytes + io_counters.write_bytes)
    time.sleep(1)

conn.close()
