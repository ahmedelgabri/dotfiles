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
    f" {cost}" if cost > 0 else None,
    f" +{added}" if added > 0 else None,
    f" -{removed}" if removed > 0 else None,
    f" in {total_duration}ms",
]

print("".join([p for p in parts if p is not None]))
