# Contributing to PostgreSQL Performance Troubleshooting Scripts

Thank you for your interest in contributing! This repository is an enterprise-grade resource used by DBAs and engineers worldwide. Please follow these guidelines to maintain quality and consistency.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Script Requirements](#script-requirements)
- [Script Header Format](#script-header-format)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)
- [Adding New Categories](#adding-new-categories)
- [Reporting Issues](#reporting-issues)

---

## Code of Conduct

This project follows a professional, inclusive standard. All contributors are expected to:
- Be respectful and constructive in all communications
- Focus feedback on code and technical accuracy, not individuals
- Help maintain the quality and reliability of scripts used in production environments

---

## Getting Started

1. **Fork** the repository on GitHub
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Troubleshooting-PostgreSQL-Performance.git
   cd Troubleshooting-PostgreSQL-Performance
   ```
3. **Set upstream** remote:
   ```bash
   git remote add upstream https://github.com/shiviyer/Troubleshooting-PostgreSQL-Performance.git
   ```
4. **Create a branch** for your work:
   ```bash
   git checkout -b feature/add-pg17-query-tracking-script
   ```

---

## How to Contribute

### Adding a New Script

1. Identify the correct category folder under `scripts/`
2. Use the naming convention: `snake_case_descriptive_name.sql` or `.py`
3. Include the full header block (see below)
4. Ensure the script is read-only (SELECT only) unless the purpose requires modification — and clearly mark any non-read-only scripts as **⚠️ MODIFYING** in the description
5. Test against all supported PostgreSQL versions (15, 16, 17, 18)
6. Update the script index table in `README.md`

### Improving an Existing Script

1. Open an Issue first describing the problem or improvement
2. Fork and branch as described above
3. Make the minimal necessary change
4. Add a version note to the header if the change affects version compatibility
5. Submit a PR referencing the issue

### Fixing Documentation

Documentation PRs are always welcome. Fix typos, improve explanations, or clarify output descriptions.

---

## Script Requirements

All scripts must meet these standards to be accepted:

### SQL Scripts

- **Read-only by default**: Use only `SELECT`, `WITH`, `EXPLAIN` statements unless explicitly documented as modifying
- **No DDL**: Never include `CREATE`, `DROP`, `ALTER`, `TRUNCATE` without a very strong reason and clear ⚠️ warning
- **Use system catalogs correctly**: Query `pg_catalog`, `information_schema`, and statistics views; never query user tables directly
- **Version guards**: If using version-specific features, document the minimum version and add a comment check:
  ```sql
  -- Requires PostgreSQL 16+
  -- Verify: SELECT current_setting('server_version_num')::int >= 160000;
  ```
- **Performance**: Scripts must not themselves cause significant load on the monitored system; avoid full table scans on large system catalogs without proper filtering
- **Idempotent**: Running a script multiple times must produce the same result (no side effects)
- **Output clarity**: Column aliases must be descriptive and human-readable

### Python Scripts

- **Python 3.8+** compatible
- Use `psycopg2` or `psycopg3` for database connections
- Accept connection parameters via command-line arguments (argparse), not hardcoded
- Include a `--help` description
- Handle connection errors gracefully with useful error messages
- Follow PEP 8 style guidelines

---

## Script Header Format

Every script **must** include this header. No exceptions.

### SQL Script Header

```sql
-- ============================================================
-- Script:      script_name.sql
-- Category:    [01_query_performance | 02_index_analysis | ...]
-- Description: One clear sentence describing what this script does
--
-- Usage:       psql -h <host> -U <user> -d <database> -f scripts/category/script_name.sql
--
--              Optional psql variables (set before running):
--              \set min_duration 5000   -- minimum duration in ms (default: 1000)
--
-- Parameters:
--   min_duration  (default: 1000)  Minimum query duration threshold in milliseconds
--
-- Output Columns:
--   pid           - Backend process ID
--   query         - Query text (truncated to track_activity_query_size)
--   duration      - Elapsed time as interval
--   wait_event    - Current wait event type and name
--
-- Dependencies:
--   - pg_stat_statements extension must be installed
--   - Requires pg_monitor role or superuser
--
-- Notes:
--   - This script is READ-ONLY and safe to run on production systems
--   - Results reflect activity since the last pg_stat_statements reset
--   - For PG17+, queryid is now consistent across databases
--
-- PG_VERSION:  15, 16, 17, 18
-- Author:      Your Name <your.email@example.com>
-- Repository:  https://github.com/shiviyer/Troubleshooting-PostgreSQL-Performance
-- Last Updated: YYYY-MM
-- ============================================================
```

### Python Script Header

```python
#!/usr/bin/env python3
"""
Script:      script_name.py
Category:    [tools]
Description: One clear sentence describing what this script does.

Usage:
    python script_name.py --host localhost --port 5432 --user postgres --dbname mydb

Arguments:
    --host      PostgreSQL host (default: localhost)
    --port      PostgreSQL port (default: 5432)
    --user      PostgreSQL user (default: postgres)
    --dbname    Database name (default: postgres)
    --interval  Sampling interval in seconds (default: 5)

Dependencies:
    pip install psycopg2-binary

Notes:
    - Requires pg_monitor role or superuser
    - Connects using psycopg2; supports SSL via PGSSLMODE environment variable

PG_VERSION:  15, 16, 17, 18
Author:      Your Name <your.email@example.com>
Repository:  https://github.com/shiviyer/Troubleshooting-PostgreSQL-Performance
Last Updated: YYYY-MM
"""
```

---

## Testing Requirements

Before submitting a PR, test your script against **all supported versions**:

```bash
# Test against PostgreSQL 15
psql -h pg15-host -U postgres -d testdb -f scripts/category/your_script.sql

# Test against PostgreSQL 16
psql -h pg16-host -U postgres -d testdb -f scripts/category/your_script.sql

# Test against PostgreSQL 17
psql -h pg17-host -U postgres -d testdb -f scripts/category/your_script.sql

# Test against PostgreSQL 18
psql -h pg18-host -U postgres -d testdb -f scripts/category/your_script.sql
```

If you can only test against some versions, clearly state which versions you tested in your PR description, and we will verify the rest during review.

**Checklist before submitting:**
- [ ] Script runs without errors on tested PG versions
- [ ] Script header is complete and accurate
- [ ] Column aliases are descriptive
- [ ] Script does not cause noticeable load on a lightly loaded test system
- [ ] README.md script index table is updated (if adding a new script)
- [ ] Commit message is clear and descriptive

---

## Pull Request Process

1. Ensure all checklist items above are complete
2. Open a PR against the `main` branch
3. Use this PR title format: `[Category] Add/Fix/Improve: Brief description`
   - Example: `[01_query_performance] Add: pg17_query_id_tracking.sql for enhanced queryid`
4. Fill out the PR description template (auto-populated when you open a PR)
5. Link any related issues with `Closes #123` or `Related to #456`
6. Wait for at least one review approval before merging

### PR Review Criteria

PRs will be reviewed for:
- Correctness against PostgreSQL system catalog documentation
- Version compatibility accuracy
- Header completeness
- Output readability
- Performance safety (script does not itself stress the system)
- Naming consistency with existing scripts

---

## Adding New Categories

If you believe a new category is needed (beyond the existing 10):

1. Open an Issue titled `[Proposal] New Category: <name>` and describe:
   - What scripts would go in this category
   - Why existing categories don't cover this area
   - How many scripts you plan to contribute initially
2. Wait for maintainer approval before creating the directory
3. New categories must have at least 3 scripts to be created

---

## Reporting Issues

For script bugs or incorrect results:
- Open a GitHub Issue with the label `bug`
- Include: PostgreSQL version, operating system, error message or unexpected output, and steps to reproduce

For script enhancement requests:
- Open a GitHub Issue with the label `enhancement`
- Describe the use case and what problem it solves

---

## Questions?

Open a GitHub Discussion or Issue — we're happy to help guide your contribution.

Thank you for helping make this the best PostgreSQL performance troubleshooting resource available! 🐘
