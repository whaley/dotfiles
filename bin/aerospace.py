"""
Shared Aerospace helper class for interacting with the aerospace window manager CLI.
"""

import json
import subprocess
from enum import Enum
from typing import List


class Direction(Enum):
    LEFT = "left"
    RIGHT = "right"
    UP = "up"
    DOWN = "down"


class Aerospace:
    def __init__(self, path: str) -> None:
        """
        path: The absolute path of the Aerospace binary (e.g. "/usr/bin/env aerospace").
        """
        self._path = path

    def _run_aerospace_command(self, cmd: str) -> str:
        full_cmd_list = self._path.split(" ") + cmd.split(" ")
        res = subprocess.run(full_cmd_list, capture_output=True)
        return res.stdout.decode("utf-8").strip() if res.stdout else ""

    def find_all_windows_for_app(self, app: str) -> List[str]:
        stdout = self._run_aerospace_command("list-windows --all --json")
        if not stdout:
            return []

        all_windows_json = json.loads(stdout)
        return [
            window.get("window-id")
            for window in all_windows_json
            if window.get("app-name", "") == app
        ]

    def find_active_workspace_name(self) -> str:
        stdout_lines = self._run_aerospace_command("list-workspaces --focused")
        return stdout_lines[0]

    def move_node_to_workspace(self, node_id: str, workspace_name: str) -> None:
        self._run_aerospace_command(
            f"move-node-to-workspace --window-id {node_id} {workspace_name}"
        )

    def list_focused_windows(self) -> List[dict]:
        stdout = self._run_aerospace_command("list-windows --workspace focused --json")
        if not stdout:
            return []
        return json.loads(stdout)

    def flatten_workspace_tree(self) -> None:
        self._run_aerospace_command("flatten-workspace-tree")

    def layout_horizontal(self) -> None:
        self._run_aerospace_command("layout horizontal")

    def join_with(self, window_id: int, direction: Direction) -> None:
        self._run_aerospace_command(
            f"join-with --window-id {window_id} {direction.value}"
        )

    def move_window(self, direction: Direction) -> None:
        self._run_aerospace_command(f"move {direction.value}")
