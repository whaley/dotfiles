#!/usr/bin/env python3
"""
If there are Obsidian windows present, move them all to the current active workspace.

If there are no Obsidian windows, call `open /Applications/Obsidian.app`, which either opens the
app, or brings it back from being minimized or hidden
"""

import subprocess
from typing import List

AEROSPACE = "/Users/whaley/homebrew/bin/aerospace"


def run_command(cmd: List[str]) -> List[str]:
    res = subprocess.run(cmd, capture_output=True)
    std_out_lines = res.stdout.decode("utf-8").split("\n") if res.stdout else []
    return std_out_lines


def find_all_obsidian_window_ids() -> List[str]:
    stdout_lines = run_command([AEROSPACE, "list-windows", "--all"])

    # Output is in the following form.  "window_id | app_name | window_title".
    # Convert each line to "window_id" only
    #
    # Example: ["18980 | iTerm2   | -zsh"] -> ["18980"]
    # Convert  ["18980", ""]

    split_lines: List[List[str]] = [line.split("|") for line in stdout_lines if line]
    return [
        line[0].strip()
        for line in split_lines
        if line and line[1].strip() == "Obsidian"
    ]


def find_active_workspace_name() -> str:
    stdout_lines = run_command([AEROSPACE, "list-workspaces", "--focused"])
    return stdout_lines[0]


if __name__ == "__main__":
    obsidian_window_ids = find_all_obsidian_window_ids()
    if obsidian_window_ids:
        active_workspace_name = find_active_workspace_name()
        for window_id in obsidian_window_ids:
            subprocess.run(
                [
                    AEROSPACE,
                    "move-node-to-workspace",
                    "--window-id",
                    window_id,
                    active_workspace_name,
                ]
            )
            subprocess.run([AEROSPACE, "focus", "--window-id", window_id])
    else:
        subprocess.run(["open", "/Applications/Obsidian.app"])
