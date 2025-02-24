#!/usr/bin/env python3
"""
If there is a Workplace window present, move it to the current active workspace.

If not, call `open $CHROME_PWA_DIR/Workplace.app`, which either opens the
app, or brings it back from being minimized or hidden
"""

import json
import subprocess
from typing import List, Optional

AEROSPACE = "/Users/whaley/homebrew/bin/aerospace"


def run_command(cmd: List[str]) -> str:
    res = subprocess.run(cmd, capture_output=True)
    return res.stdout.decode("utf-8") if res.stdout else ""


def find_workplace_window_id() -> Optional[int]:
    stdout = run_command([AEROSPACE, "list-windows", "--all", "--json"])
    if not stdout:
        return None

    # Output is in the following form.
    # [
    #   {
    #     "app-name" : "Workplace",
    #     "window-title" : "",
    #     "window-id" : 1234
    #   }
    #   ...
    # ]

    all_windows_json = json.loads(stdout)
    filtered = [app for app in all_windows_json if app["app-name"] == "Workplace"]
    return filtered[0].get("window-id", "") if filtered else None


def find_active_workspace_name() -> str:
    stdout_lines = run_command([AEROSPACE, "list-workspaces", "--focused"])
    return stdout_lines[0]


if __name__ == "__main__":
    workplace_window_id = find_workplace_window_id()
    if workplace_window_id:
        active_workspace_name = find_active_workspace_name()
        subprocess.run(
            [
                AEROSPACE,
                "move-node-to-workspace",
                "--window-id",
                str(workplace_window_id),
                active_workspace_name,
                "--fail-if-noop",
            ]
        )
        subprocess.run([AEROSPACE, "focus", "--window-id", str(workplace_window_id)])

    else:
        subprocess.run(
            ["open", "/Users/whaley/Applications/Chrome Apps.localized/Workplace.app"]
        )
