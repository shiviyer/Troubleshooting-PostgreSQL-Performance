# 🐘 PostgreSQL Performance Troubleshooting Scripts

> **Enterprise-Grade Collection of 100 Diagnostic & Performance Tuning Scripts for PostgreSQL 15, 16, 17, and 18**

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15%20|%2016%20|%2017%20|%2018-336791?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
[![Scripts](https://img.shields.io/badge/Scripts-100-brightgreen?style=for-the-badge)]()
[![PRs Welcome](https://img.shields.io/badge/PRs-Welcome-brightgreen.svg?style=for-the-badge)](CONTRIBUTING.md)
[![Maintained](https://img.shields.io/badge/Maintained-Yes-green.svg?style=for-the-badge)]()

---

## 📖 Table of Contents

- [Overview](#overview)
- [Why This Repository?](#why-this-repository)
- [Quick Start](#quick-start)
- [Repository Structure](#repository-structure)
- [Script Categories & Index](#script-categories--index)
- [PostgreSQL Version Compatibility Matrix](#postgresql-version-compatibility-matrix)
- [Prerequisites](#prerequisites)
- [Usage Guide](#usage-guide)
- [Script Header Convention](#script-header-convention)
- [Contributing](#contributing)
- [License](#license)
- [Author](#author)

---

## Overview

This repository is the definitive, enterprise-grade collection of **100 production-ready SQL and Python scripts** designed for Database Administrators, Performance Engineers, and Site Reliability Engineers who manage PostgreSQL deployments at scale. Every script is:

- ✅ **Tested** against PostgreSQL 15, 16, 17, and 18
- ✅ **Documented** with purpose, parameters, expected output, and version notes
- ✅ **Production-Safe** — all diagnostic scripts are read-only unless explicitly noted
- ✅ **Categorized** into 10 logical domains for rapid troubleshooting
- ✅ **Version-aware** — highlights behavioral differences across PG versions

---

## Why This Repository?

PostgreSQL performance troubleshooting requires deep knowledge of its internals: the query planner, MVCC, WAL, buffer pool, autovacuum, lock manager, and more. These scripts encode years of field experience troubleshooting databases ranging from single-node setups to multi-terabyte sharded clusters.

**Use cases include:**
- Real-time incident response and outage diagnosis
- Proactive performance monitoring and capacity planning
- Query optimization and index tuning
- Autovacuum tuning and bloat management
- Replication lag diagnosis and HA health checks
- Connection pool sizing and idle session cleanup
- Memory pressure and cache hit rate analysis
- Lock contention and deadlock forensics

---

## Quick Start

```bash
# Clone the repository
git clone https://github.com/shiviyer/Troubleshooting-PostgreSQL-Performance.git
cd Troubleshooting-PostgreSQL-Performance

# Run any SQL script directly against your database
psql -h <host> -U <user> -d <database> -f scripts/01_query_performance/top_slow_queries.sql

# Or paste into psql interactively
psql -h <host> -U <user> -d <database>
\i scripts/01_query_performance/top_slow_queries.sql
```

> **Tip:** Most scripts require the `pg_stat_statements` extension. Enable it with:
> ```sql
> CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
> ```
> And add `pg_stat_statements` to `shared_preload_libraries` in `postgresql.conf`.

---

## Repository Structure

```
Troubleshooting-PostgreSQL-Performance/
├── README.md
├── CONTRIBUTING.md
├── LICENSE
├── CHANGELOG.md
├── scripts/
│   ├── 01_query_performance/      # 20 scripts
│   ├── 02_index_analysis/         # 10 scripts
│   ├── 03_vacuum_bloat/           # 10 scripts
│   ├── 04_lock_concurrency/       # 10 scripts
│   ├── 05_connection_session/     # 10 scripts
│   ├── 06_replication_ha/         # 10 scripts
│   ├── 07_io_storage/             # 10 scripts
│   ├── 08_memory_caching/         # 10 scripts
│   ├── 09_autovacuum_maintenance/  # 5 scripts
│   └── 10_wait_events_statistics/ # 5 scripts
└── tools/
    ├── PSQL-Top-Idx.py
    ├── PostgreSQL-slow-log-analyzer.py
    ├── pg-thread-perf.py
    ├── psql-cache-trash.py
    └── top-sql.py
```

---

## Script Categories & Index

### 01 · Query Performance (20 scripts)

| # | Script | Description | PG Versions |
|---|--------|-------------|-------------|
| 01 | `top_slow_queries.sql` | Top 25 slowest queries by total execution time from pg_stat_statements | 15–18 |
| 02 | `long_running_queries.sql` | Active queries running longer than a configurable threshold | 15–18 |
| 03 | `query_forensics.sql` | Full forensic view of active queries with plan, locks, and waits | 15–18 |
| 04 | `query_plan_regression.sql` | Detect queries with high variance in execution time (plan instability) | 15–18 |
| 05 | `top_io_queries.sql` | Top 20 queries by physical and logical I/O reads | 15–18 |
| 06 | `top_temp_usage_queries.sql` | Queries generating the most temporary file usage | 15–18 |
| 07 | `queries_missing_indexes.sql` | Queries performing sequential scans on large tables | 15–18 |
| 08 | `parallel_query_status.sql` | Identify queries eligible for vs using parallel execution | 15–18 |
| 09 | `query_wait_breakdown.sql` | Per-query wait event distribution from pg_stat_activity sampling | 15–18 |
| 10 | `pg_stat_statements_reset_impact.sql` | Analyze impact of pg_stat_statements resets on query trends | 15–18 |
| 11 | `explain_analyze_helper.sql` | Parameterized EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) wrapper | 15–18 |
| 12 | `jit_compilation_queries.sql` | Queries benefiting from or hindered by JIT compilation | 15–18 |
| 13 | `top_memory_queries.sql` | Top queries by work_mem allocation and sort/hash usage | 15–18 |
| 14 | `query_age_histogram.sql` | Histogram of currently running query durations | 15–18 |
| 15 | `idle_in_transaction_queries.sql` | Detect idle-in-transaction sessions with open transactions | 15–18 |
| 16 | `query_cancels_and_errors.sql` | Queries with high cancellation or error rates | 15–18 |
| 17 | `pg17_query_id_tracking.sql` | Enhanced queryid tracking using PG17+ improvements | 17–18 |
| 18 | `normalized_query_fingerprints.sql` | Grouped normalized query fingerprint report | 15–18 |
| 19 | `query_calls_per_second.sql` | Compute queries-per-second rate from pg_stat_statements snapshots | 15–18 |
| 20 | `top_row_estimate_errors.sql` | Queries where planner row estimates deviate most from actual rows | 15–18 |

### 02 · Index Analysis (10 scripts)

| # | Script | Description | PG Versions |
|---|--------|-------------|-------------|
| 21 | `unused_indexes.sql` | Indexes never scanned since last statistics reset | 15–18 |
| 22 | `duplicate_indexes.sql` | Structurally equivalent or redundant indexes | 15–18 |
| 23 | `index_bloat_estimate.sql` | Estimated bloat ratio for B-tree indexes | 15–18 |
| 24 | `index_hit_rate.sql` | Index vs. sequential scan ratios per table | 15–18 |
| 25 | `missing_primary_keys.sql` | Tables without a primary key or unique constraint | 15–18 |
| 26 | `partial_index_opportunities.sql` | Tables where partial indexes could reduce size significantly | 15–18 |
| 27 | `index_usage_stats.sql` | Complete index usage statistics with size and scan counts | 15–18 |
| 28 | `brin_index_candidates.sql` | Large tables with monotonically increasing columns (BRIN candidates) | 15–18 |
| 29 | `invalid_indexes.sql` | Detect INVALID indexes left by failed CREATE INDEX CONCURRENTLY | 15–18 |
| 30 | `top_idx_py_analyzer.sql` | SQL companion to PSQL-Top-Idx.py Python analyzer | 15–18 |

### 03 · Vacuum & Bloat (10 scripts)

| # | Script | Description | PG Versions |
|---|--------|-------------|-------------|
| 31 | `table_bloat_estimate.sql` | Estimate table bloat using pgstattuple-compatible formulas | 15–18 |
| 32 | `dead_tuple_hotspots.sql` | Tables with the highest dead tuple counts and ratios | 15–18 |
| 33 | `vacuum_progress_monitor.sql` | Real-time VACUUM progress via pg_stat_progress_vacuum | 15–18 |
| 34 | `last_vacuum_analyze_times.sql` | Last vacuum/analyze timestamps and table modification stats | 15–18 |
| 35 | `tables_needing_vacuum.sql` | Tables approaching autovacuum thresholds with urgency ranking | 15–18 |
| 36 | `toast_bloat.sql` | TOAST table bloat associated with parent tables | 15–18 |
| 37 | `freeze_wraparound_risk.sql` | Tables at risk of transaction ID wraparound | 15–18 |
| 38 | `vacuum_cost_impact.sql` | I/O impact of running VACUUM on production workloads | 15–18 |
| 39 | `pg16_vacuum_stats_enhanced.sql` | Enhanced vacuum statistics available from PG16+ | 16–18 |
| 40 | `index_bloat_candidates_vacuum.sql` | Indexes with high bloat requiring REINDEX or VACUUM FULL | 15–18 |

### 04 · Lock & Concurrency (10 scripts)

| # | Script | Description | PG Versions |
|---|--------|-------------|-------------|
| 41 | `detect_blocking_queries.sql` | All blocking/waiting query pairs with lock type and duration | 15–18 |
| 42 | `lock_tree_hierarchy.sql` | Full lock dependency tree for complex blocking chains | 15–18 |
| 43 | `deadlock_detection.sql` | Recent deadlock events extracted from pg_log with context | 15–18 |
| 44 | `lock_wait_histogram.sql` | Histogram of lock wait durations across active sessions | 15–18 |
| 45 | `relation_lock_summary.sql` | Lock modes held per relation with holder query info | 15–18 |
| 46 | `advisory_lock_audit.sql` | Sessions holding advisory locks and associated queries | 15–18 |
| 47 | `hot_row_contention.sql` | Tables experiencing high UPDATE contention on the same rows | 15–18 |
| 48 | `serialization_failures.sql` | Serialization and deadlock error rates from pg_stat_database | 15–18 |
| 49 | `lock_timeout_candidates.sql` | Queries that frequently hit lock_timeout limits | 15–18 |
| 50 | `lwlock_contention.sql` | Lightweight lock (LWLock) wait events from pg_stat_activity | 15–18 |

### 05 · Connection & Session Management (10 scripts)

| # | Script | Description | PG Versions |
|---|--------|-------------|-------------|
| 51 | `connection_summary.sql` | Connection count by state, user, database, and application | 15–18 |
| 52 | `connection_limit_proximity.sql` | Databases and users approaching max_connections limits | 15–18 |
| 53 | `idle_session_audit.sql` | Sessions idle for more than a configurable threshold | 15–18 |
| 54 | `idle_in_transaction_audit.sql` | Sessions idle-in-transaction sorted by duration | 15–18 |
| 55 | `session_activity_overview.sql` | Complete session state overview with wait events and query age | 15–18 |
| 56 | `pg_hba_connection_origins.sql` | Connection origins by IP, user, and auth method | 15–18 |
| 57 | `connection_pool_sizing_advisor.sql` | Recommendations for PgBouncer/connection pool sizing | 15–18 |
| 58 | `backend_memory_usage.sql` | Per-backend memory allocation estimates | 15–18 |
| 59 | `walsender_connections.sql` | WAL sender connections for replication and monitoring | 15–18 |
| 60 | `long_idle_transaction_killer.sql` | Generates TERMINATE statements for long-idle-in-transaction sessions | 15–18 |

### 06 · Replication & High Availability (10 scripts)

| # | Script | Description | PG Versions |
|---|--------|-------------|-------------|
| 61 | `streaming_replication_status.sql` | Streaming replication lag in bytes and seconds per standby | 15–18 |
| 62 | `replication_slot_lag.sql` | Replication slot lag and risk of WAL accumulation | 15–18 |
| 63 | `logical_replication_status.sql` | Logical replication subscription status and lag | 15–18 |
| 64 | `standby_query_conflicts.sql` | Query conflicts on standby servers (recovery conflicts) | 15–18 |
| 65 | `wal_generation_rate.sql` | WAL generation rate (bytes/second) to size WAL archiving | 15–18 |
| 66 | `wal_receiver_status.sql` | WAL receiver status on standby servers | 15–18 |
| 67 | `replication_slot_blocker.sql` | Inactive replication slots causing WAL retention | 15–18 |
| 68 | `pg16_logical_replication_stats.sql` | Enhanced logical replication stats from PG16 system catalogs | 16–18 |
| 69 | `failover_readiness_check.sql` | Pre-failover health checklist for standby promotion readiness | 15–18 |
| 70 | `archive_status_monitor.sql` | WAL archive backlog and archiver process status | 15–18 |

### 07 · I/O & Storage (10 scripts)

| # | Script | Description | PG Versions |
|---|--------|-------------|-------------|
| 71 | `bgwriter_checkpoint_stats.sql` | Background writer and checkpoint statistics with tuning hints | 15–18 |
| 72 | `table_io_stats.sql` | Table-level heap, index, and TOAST I/O statistics | 15–18 |
| 73 | `index_io_stats.sql` | Per-index block read vs. buffer hit statistics | 15–18 |
| 74 | `disk_io_hotspots.sql` | Relations with highest physical block reads (I/O hotspots) | 15–18 |
| 75 | `checkpoint_frequency_analysis.sql` | Checkpoint frequency vs. configured checkpoint_completion_target | 15–18 |
| 76 | `tablespace_usage.sql` | Tablespace size, location, and object counts | 15–18 |
| 77 | `database_size_trend.sql` | Per-database object sizes sorted by growth indicators | 15–18 |
| 78 | `wal_disk_usage.sql` | Current WAL directory size and segment count | 15–18 |
| 79 | `temp_file_usage.sql` | Per-database temporary file usage (spills to disk) | 15–18 |
| 80 | `pg15_io_stats.sql` | pg_stat_io view (PG15+) — detailed I/O accounting | 15–18 |

### 08 · Memory & Caching (10 scripts)

| # | Script | Description | PG Versions |
|---|--------|-------------|-------------|
| 81 | `cache_hit_rate_global.sql` | Global and per-database buffer cache hit ratios | 15–18 |
| 82 | `table_cache_hit_rate.sql` | Per-table cache hit ratio to identify cold or thrashed tables | 15–18 |
| 83 | `shared_buffer_usage.sql` | Shared buffer occupancy via pg_buffercache extension | 15–18 |
| 84 | `work_mem_spill_queries.sql` | Queries spilling to disk due to insufficient work_mem | 15–18 |
| 85 | `effective_cache_size_advisor.sql` | Estimate optimal effective_cache_size based on OS cache | 15–18 |
| 86 | `pg_buffercache_top_relations.sql` | Top relations by shared buffer pages cached | 15–18 |
| 87 | `wal_buffers_utilization.sql` | WAL buffer utilization and flush frequency | 15–18 |
| 88 | `sort_hash_memory_usage.sql` | Sort and hash aggregate memory usage from query execution stats | 15–18 |
| 89 | `memory_context_summary.sql` | Backend memory context breakdown via pg_backend_memory_contexts | 13–18 |
| 90 | `huge_pages_status.sql` | Huge pages allocation status and effectiveness | 15–18 |

### 09 · Autovacuum & Maintenance (5 scripts)

| # | Script | Description | PG Versions |
|---|--------|-------------|-------------|
| 91 | `autovacuum_worker_status.sql` | Currently running autovacuum workers and their target tables | 15–18 |
| 92 | `autovacuum_tuning_advisor.sql` | Per-table autovacuum threshold recommendations based on size/churn | 15–18 |
| 93 | `transaction_id_age_risk.sql` | Tables sorted by transaction ID age proximity to wraparound limit | 15–18 |
| 94 | `autovacuum_history_from_logs.sql` | Parse autovacuum activity from PostgreSQL log files | 15–18 |
| 95 | `multixact_age_risk.sql` | Multixact ID age risk (member limits approaching) | 15–18 |

### 10 · Wait Events & Statistics (5 scripts)

| # | Script | Description | PG Versions |
|---|--------|-------------|-------------|
| 96 | `wait_event_profile.sql` | Sample-based wait event profile across all active backends | 15–18 |
| 97 | `top_wait_events_by_query.sql` | Per-query wait event summary from pg_stat_activity | 15–18 |
| 98 | `pg_stat_database_overview.sql` | Comprehensive per-database statistics dashboard | 15–18 |
| 99 | `background_process_waits.sql` | Wait events for background workers | 15–18 |
| 100 | `pg18_wait_events_enhanced.sql` | New wait event categories introduced in PostgreSQL 18 | 18 |

---

## PostgreSQL Version Compatibility Matrix

| Feature / View | PG 15 | PG 16 | PG 17 | PG 18 |
|----------------|-------|-------|-------|-------|
| `pg_stat_statements` | ✅ | ✅ | ✅ | ✅ |
| `pg_stat_io` | ✅ | ✅ | ✅ | ✅ |
| `pg_stat_progress_vacuum` | ✅ | ✅ | ✅ | ✅ |
| `pg_buffercache` extension | ✅ | ✅ | ✅ | ✅ |
| `pg_backend_memory_contexts` | ✅ | ✅ | ✅ | ✅ |
| Logical replication enhanced stats | ❌ | ✅ | ✅ | ✅ |
| JIT expression caching improvements | ❌ | ✅ | ✅ | ✅ |
| Enhanced queryid tracking | ❌ | ❌ | ✅ | ✅ |
| Asynchronous I/O (expanded pg_stat_io) | ❌ | ❌ | ❌ | ✅ |
| `pg_stat_replication_slots` | ✅ | ✅ | ✅ | ✅ |

> Scripts that use version-specific features include a **`-- PG_VERSION:`** comment header noting the minimum version required.

---

## Prerequisites

**Required Extensions:**
```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;  -- Query performance scripts
CREATE EXTENSION IF NOT EXISTS pg_buffercache;       -- Memory/caching scripts
CREATE EXTENSION IF NOT EXISTS pgstattuple;          -- Precise bloat estimation
```

**Required postgresql.conf settings:**
```ini
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.track = all
pg_stat_statements.max = 10000
log_min_duration_statement = 1000
log_lock_waits = on
log_checkpoints = on
log_autovacuum_min_duration = 250
track_io_timing = on
track_activity_query_size = 4096
```

**Required Privileges:**
```sql
GRANT pg_monitor TO your_dba_user;
GRANT pg_read_all_stats TO your_dba_user;
```

---

## Usage Guide

### Running SQL Scripts

```bash
# Run a single script
psql -h localhost -U postgres -d mydb -f scripts/01_query_performance/top_slow_queries.sql

# Run with variable substitution
psql -h localhost -U postgres -d mydb \
  -v min_duration=5000 \
  -f scripts/01_query_performance/long_running_queries.sql
```

### Typical Troubleshooting Workflows

**High CPU:**
1. `scripts/01_query_performance/top_slow_queries.sql`
2. `scripts/01_query_performance/parallel_query_status.sql`
3. `scripts/10_wait_events_statistics/wait_event_profile.sql`

**High I/O:**
1. `scripts/07_io_storage/disk_io_hotspots.sql`
2. `scripts/01_query_performance/top_io_queries.sql`
3. `scripts/07_io_storage/bgwriter_checkpoint_stats.sql`

**Lock/Blocking:**
1. `scripts/04_lock_concurrency/detect_blocking_queries.sql`
2. `scripts/04_lock_concurrency/lock_tree_hierarchy.sql`
3. `scripts/04_lock_concurrency/deadlock_detection.sql`

**Vacuum/Bloat Emergency:**
1. `scripts/03_vacuum_bloat/freeze_wraparound_risk.sql`
2. `scripts/03_vacuum_bloat/dead_tuple_hotspots.sql`
3. `scripts/09_autovacuum_maintenance/autovacuum_worker_status.sql`

---

## Script Header Convention

Every script follows this documentation standard:

```sql
-- ============================================================
-- Script:      script_name.sql
-- Category:    [Category Name]
-- Description: One-line purpose summary
--
-- Usage:       psql -f scripts/category/script_name.sql
--              Optional: \set variable_name 'value' before running
--
-- Parameters:  variable_name (default: value) — description
--
-- Output:      Description of columns returned
--
-- Notes:       - Any important behavioral notes
--              - Side effects (most scripts are read-only)
--
-- PG_VERSION:  15, 16, 17, 18
-- Author:      Shiv Iyer
-- Repository:  https://github.com/shiviyer/Troubleshooting-PostgreSQL-Performance
-- Last Updated: 2025-01
-- ============================================================
```

---

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Code style and header format requirements
- Testing against multiple PostgreSQL versions
- Pull request process
- Adding new script categories

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## Author

**Shiv Iyer** — PostgreSQL Performance Expert & Database Architect
- GitHub: [@shiviyer](https://github.com/shiviyer)
- Repository: [Troubleshooting-PostgreSQL-Performance](https://github.com/shiviyer/Troubleshooting-PostgreSQL-Performance)

---

*⭐ If this repository saves you time during a production incident, please consider starring it!*
