-- Synthetic atuin history (only the columns import-atuin reads).
CREATE TABLE history (
    id TEXT PRIMARY KEY,
    timestamp INTEGER NOT NULL,
    command TEXT NOT NULL,
    cwd TEXT NOT NULL,
    author TEXT NOT NULL,
    author_kind INTEGER NOT NULL,
    deleted_at INTEGER
);
INSERT INTO history VALUES
    ('a', 1767225600000000000, 'ls -la', '/r', 'claude-code', 2, NULL),
    ('b', 1767225660000000000, 'git status', '/r/a', 'codex', 2, NULL),
    ('c', 1767225720000000000, 'typed by hand', '/r', 'ahmed', 1, NULL),
    ('d', 1767225780000000000, 'deleted', '/r', 'claude-code', 2, 1767225790000000000),
    ('e', 1767225840000000000, 'pi thing', '/r/b', 'pi', 2, NULL);
