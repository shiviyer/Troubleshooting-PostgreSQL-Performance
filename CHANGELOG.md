# Changelog

All notable changes to this repository are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [2.0.0] - 2025-01

### Added — Enterprise Upgrade

This release transforms the repository from a loose collection of scripts into a fully
documented, enterprise-grade PostgreSQL performance troubleshooting toolkit.

#### Documentation
- Added comprehensive `README.md` with:
  - 100-script catalog organized into 10 categories
  - PostgreSQL 15/16/17/18 version compatibility matrix
  - Quick start guide and usage workflows
  - Prerequisites and required extensions
  - Script header convention standard
- Added `CONTRIBUTING.md` with:
  - Script requirements and quality standards
  - Mandatory script header format (SQL and Python)
  - Testing requirements across PG versions
  - Pull request process and review criteria
- Added `LICENSE` (MIT)
- Added `CHANGELOG.md` (this file)

#### New Script Categories (scripts/*)
- `01_query_performance/` — 20 scripts covering pg_stat_statements, query forensics,
  JIT analysis, parallel query, plan regression detection, and per-query wait events
- `02_index_analysis/` — 10 scripts covering unused/duplicate/invalid indexes,
  bloat estimation, BRIN candidates, and partial index opportunities
- `03_vacuum_bloat/` — 10 scripts covering dead tuple hotspots, TOAST bloat,
  freeze/wraparound risk, vacuum progress monitoring, and PG16 enhanced vacuum stats
- `04_lock_concurrency/` — 10 scripts covering lock trees, deadlock detection,
  advisory locks, serialization failures, and LWLock contention
- `05_connection_session/` — 10 scripts covering connection limits, idle sessions,
  pool sizing advisors, backend memory, and WAL sender connections
- `06_replication_ha/` — 10 scripts covering streaming replication lag, slot lag,
  logical replication, WAL generation rate, and failover readiness
- `07_io_storage/` — 10 scripts covering disk I/O hotspots, bgwriter/checkpoint stats,
  pg_stat_io (PG15+), temp file usage, and tablespace monitoring
- `08_memory_caching/` — 10 scripts covering cache hit rates, pg_buffercache,
  work_mem spills, huge pages, WAL buffer utilization, and memory contexts
- `09_autovacuum_maintenance/` — 5 scripts covering autovacuum workers, tuning advisors,
  transaction ID age risk, multixact age risk, and log parsing
- `10_wait_events_statistics/` — 5 scripts covering wait event profiling,
  pg_stat_database overview, background process waits, and PG18 new wait events

#### New Individual Scripts (100 total)
See README.md for the complete indexed catalog of all 100 scripts.

---

## [1.0.0] - 2023 (Original Release)

### Added
- `detect_blocking_queries.sql` — Detect blocking and waiting query pairs
- `long-running-queries.sql` — Find long-running active queries
- `pg-avg-queue-length.sql` — Average queue length monitoring
- `pg-block.sql` — Block detection
- `pg-del-diskIO.sql` — Disk I/O delta monitoring
- `pg-forecast-cpu.sql` — CPU forecast metrics
- `pg-lock-time.sql` — Lock time analysis
- `pg-queries-mutex.sql` — Mutex/lock contention for queries
- `pg-query-forensics.sql` — Query forensics
- `pg-session-activities.sql` — Session activity overview
- `pg_activities_blocks.sql` — Activities and blocks monitor
- `pg_deadlock_detect.sql` — Deadlock detection
- `pg_disk_stat.sql` — Disk statistics
- `pg_query_mutex_contention.sql` — Query mutex contention
- `pg_wait_resource.sql` — Wait resource analysis
- `postgres-bgwrtr-ckpt.sql` — Background writer and checkpoint stats
- `PSQL-Top-Idx.py` — Top index usage analyzer (Python)
- `PostgreSQL-slow-log-analyzer.py` — Slow log parser (Python)
- `pg-thread-perf.py` — Thread performance monitor (Python)
- `psql-cache-trash.py` — Cache efficiency analyzer (Python)
- `top-sql.py` — Top SQL monitor (Python)

---

## Planned

- GitHub Actions CI workflow to test scripts against PG15/16/17/18 Docker containers
- Script output examples (sample output files per script)
- pgBadger integration guide
- Grafana dashboard JSON templates using these queries as data sources
- Shell script automation wrappers for common workflows
