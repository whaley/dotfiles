#!/usr/bin/env python3
"""
Retile windows on the focused workspace into a two-row horizontal layout.

If the focused workspace has more than 2 windows, flatten the workspace tree,
set a horizontal layout, then join every even-indexed window to the left so
they stack into a second row.
"""

import argparse

from aerospace import Aerospace, Direction


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Retile focused workspace windows into a two-row layout"
    )
    parser.add_argument(
        "--aerospace-path",
        type=str,
        help="The absolute path of the aerospace binary.  If not specified then /usr/bin/env aerospace is used",
        default="",
    )

    args = parser.parse_args()
    args.aerospace_path = (
        args.aerospace_path.strip() if args.aerospace_path else "/usr/bin/env aerospace"
    )

    return args


if __name__ == "__main__":
    args = parse_args()
    aerospace = Aerospace(args.aerospace_path)
    windows = aerospace.list_focused_windows()

    if len(windows) > 2:
        aerospace.flatten_workspace_tree()
        aerospace.layout_horizontal()

        for i, window in enumerate(windows):
            if i % 2 == 0:
                window_id = window.get("window-id")
                if window_id is not None:
                    aerospace.join_with(window_id, Direction.LEFT)
