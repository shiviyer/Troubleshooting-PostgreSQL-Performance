SELECT
    checkpoints_timed,      -- Number of scheduled checkpoints that have been performed
    checkpoints_req,        -- Number of requested checkpoints that have been performed
    buffers_checkpoint,     -- Number of buffers written during checkpoints
    buffers_clean,          -- Number of buffers written by the background writer
    maxwritten_clean,       -- Number of background writer stopped due to max write count
    buffers_backend,        -- Number of buffers written directly by a backend
    buffers_backend_fsync,  -- Number of times a backend had to execute its own fsync call
    buffers_alloc            -- Number of buffers allocated
FROM pg_stat_bgwriter;



