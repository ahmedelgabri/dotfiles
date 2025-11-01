#!/usr/bin/env python3

# See: https://anthropic.mintlify.app/en/docs/claude-code/statusline

import json
import os
import subprocess
import sys

# Read JSON from stdin
data = json.load(sys.stdin)


# Extract values
model = data["model"]["display_name"]
current_dir = os.path.basename(data["workspace"]["current_dir"])
added = data["cost"]["total_lines_added"]
removed = data["cost"]["total_lines_removed"]
total_duration = data["cost"]["total_duration_ms"]
cost = data["cost"]["total_cost_usd"]


# Format helpers
def format_cost(cost_usd):
    """Format cost as currency with appropriate precision."""
    if cost_usd < 0.01:
        return f"${cost_usd:.4f}"
    elif cost_usd < 1:
        return f"${cost_usd:.3f}"
    else:
        return f"${cost_usd:.2f}"


def format_duration(ms):
    """Format duration, converting to seconds for large values."""
    if ms >= 1000:
        return f"{ms / 1000:.1f}s"
    else:
        return f"{ms}ms"


def format_lines(count):
    """Format line count with thousand separators."""
    return f"{count:,}"


# Check for git branch
git_branch = ""
try:
    # Check if in a git repository
    subprocess.run(["git", "rev-parse", "--git-dir"], capture_output=True, check=True)

    # Get current branch
    result = subprocess.run(
        ["git", "branch", "--show-current"],
        capture_output=True,
        text=True,
        check=True,
    )

    git_branch = result.stdout.strip()

except subprocess.CalledProcessError:
    pass


parts = [
    f"/{current_dir}",
    f" {git_branch}:",
    f" [{model}]",
    f" {format_cost(cost)}" if cost > 0 else None,
    f" +{format_lines(added)}" if added > 0 else None,
    f" -{format_lines(removed)}" if removed > 0 else None,
    f" in {format_duration(total_duration)}",
]

print("".join([p for p in parts if p is not None]))
