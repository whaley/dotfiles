#!/usr/bin/env python3
"""
Move the focused window to the edge of the workspace in a given direction.

Since aerospace does not expose the layout tree (see github.com/nikitabobko/AeroSpace/issues/16),
we brute-force by calling `aerospace move <direction>` a number of times equal to the total window
count in the focused workspace, which guarantees the window reaches the edge regardless of its
current position in the tree.
"""

import argparse

from aerospace import Aerospace, Direction


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Move the focused window to the edge of the workspace in a given direction"
    )
    parser.add_argument(
        "direction",
        type=Direction,
        choices=list(Direction),
        help="The direction to move the window (left, right, up, down)",
    )
    parser.add_argument(
        "--aerospace-path",
        type=str,
        help="The absolute path of the aerospace binary. Defaults to /usr/bin/env aerospace",
        default="/usr/bin/env aerospace",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    aerospace = Aerospace(args.aerospace_path)

    # Brute-force: move the window N times where N is the total number of windows
    # in the workspace. This guarantees we reach the edge since we can't inspect the
    # layout tree to know how many moves are actually needed.
    for _ in aerospace.list_focused_windows():
        aerospace.move_window(args.direction)
