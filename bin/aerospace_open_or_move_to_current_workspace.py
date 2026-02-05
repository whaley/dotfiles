#!/usr/bin/env python3
"""
Using aerospace, if there are windows present of the app, move them all to the current active workspace.

If there are no windows, open that application using MacOS's open utility which either opens the
app, or brings it back from being minimized or hidden.
"""

import argparse
import json
import subprocess
from typing import List


class Aerospace:
    def __init__(self, path: str) -> None:
        """
        path: The absolute path of the Aerospace binary.
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

        # stdout is in the following form.
        # [
        #   {
        #     "app-name" : "Workchat",
        #     "window-title" : "",
        #     "window-id" : 1234
        #   }
        #   ...
        # ]

        all_windows_json = json.loads(stdout)
        return [window.get("window-id") for window in all_windows_json if window.get("app-name","") == app]

    def find_active_workspace_name(self) -> str:
        stdout_lines = self._run_aerospace_command("list-workspaces --focused")
        return stdout_lines[0]

    def move_node_to_workspace(self, node_id: str, workspace_name: str) -> None:
        self._run_aerospace_command(f"move-node-to-workspace --window-id {node_id} {workspace_name}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Move a window to the current active workspace"
    )
    parser.add_argument(
        "app",
        type=str,
        help="The name of the app as it appears when reported by `aerospace list-windows`",
    )

    parser.add_argument(
        "--app-path",
        type=str,
        help="The absolute path of the app.  If not specified then a location of /Applications/appname.app is used",
        default="",
    )

    parser.add_argument(
        "--aerospace-path",
        type=str,
        help="The absolute path of the aerospace binary.  If not specified then /usr/bin/env aerospace is used",
        default="",
    )

    args =  parser.parse_args()

    args.app = args.app.strip()
    args.app_path = args.app_path.strip() if args.app_path else f"/Applications/{args.app}.app"
    args.aerospace_path = args.aerospace_path.strip() if args.aerospace_path else "/usr/bin/env aerospace"

    return args

if __name__ == "__main__":
    args = parse_args()
    aerospace = Aerospace(args.aerospace_path)

    window_ids: List[str] = aerospace.find_all_windows_for_app(args.app)
    if window_ids:
        active_workspace_name: str = aerospace.find_active_workspace_name()
        for window_id in window_ids:
              aerospace.move_node_to_workspace(window_id, active_workspace_name)
    else:
         subprocess.run(["open", args.app_path])
