import psycopg2
import time

conn = psycopg2.connect(database="your_database_name", user="your_username", password="your_password", host="your_host_ip", port="your_port")
cur = conn.cursor()

while True:
    cur.execute("""SELECT pid, usename, application_name, client_addr, client_port, datname, query, state, backend_start, query_start, now() - query_start as latency
                   FROM pg_stat_activity
                   WHERE state = 'active'
                   ORDER BY query_start""")
    rows = cur.fetchall()
    print("PID\tUSER\tAPP_NAME\tCLIENT_IP\tCLIENT_PORT\tDATABASE\tSTATE\tBACKEND_START\tQUERY_START\tLATENCY\tQUERY")
    for row in rows:
        print(f"{row[0]}\t{row[1]}\t{row[2]}\t{row[3]}\t{row[4]}\t{row[5]}\t{row[7]}\t{row[8]}\t{row[9]}\t{row[10]}\t{row[6]}")
    time.sleep(5)
