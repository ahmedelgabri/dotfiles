-- Synthetic agent history for the golden tests. Never real history.
CREATE TABLE commands (
    id INTEGER PRIMARY KEY,
    ts INTEGER NOT NULL,
    agent TEXT NOT NULL,
    cwd TEXT NOT NULL,
    cmd TEXT NOT NULL,
    session TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'ran',
    description TEXT NOT NULL DEFAULT ''
);
CREATE INDEX commands_ts ON commands (ts);
CREATE INDEX commands_cwd ON commands (cwd);
CREATE INDEX commands_session ON commands (session);
INSERT INTO commands (id, ts, agent, cwd, cmd, session, status, description) VALUES
    (1, 1767225600, 'claude', '/r/a', 'echo dup', 's1', 'ran', 'first dup'),
    (2, 1767225660, 'pi', '/r/b', 'solo', 's2', 'ran', ''),
    (3, 1767225720, 'claude', '/r/b', 'echo dup', 's1', 'ran', 'second dup'),
    (4, 1767225780, 'claude', '/r/c', 'echo dup', 's3', 'failed', 'failed dup'),
    (5, 1767225840, 'codex', '/r/a', 'rm denied', '', 'failed', ''),
    (6, 1767225900, 'claude', '/r/dir with spaces', '  spaced cmd  ', 's1', 'ran', ''),
    (7, 1767225960, 'claude', '/r/a/sub', 'line one' || char(10) || '  line two' || char(10), 's1', 'ran', 'multi'),
    (8, 1767226020, 'pi', '/r/a', 'tab' || char(9) || 'inside', '', 'ran', ''),
    (9, 1767226080, 'codex', '/r', '', '', 'ran', ''),
    (10, 1767226140, 'claude', '/r', 'nbsp' || char(160) || 'word em' || char(8195) || 'space', 's2', 'ran', 'unicode'),
    (11, 1772951400, 'claude', '/dst', 'before dst', 's4', 'ran', ''),
    (12, 1772955000, 'claude', '/dst', 'after dst', 's4', 'ran', ''),
    (13, 99999999999999, 'claude', '/far', 'far future', '', 'ran', 'out of range'),
    (14, 1767226200, 'claude', '/r/a', 'nix build .#x', 's1', 'failed', ''),
    (15, 1767226260, 'claude', '/r/a', 'nix build .#y', 's1', 'ran', ''),
    (16, 1767226320, 'claude', '/r/a', 'jj log -r @', 's1', 'ran', ''),
    (17, 1767226380, 'pi', '/r/b', 'jj log --no-graph', 's2', 'ran', ''),
    (18, 1767226380, 'pi', '/r/b', 'same second', 's2', 'ran', '');
