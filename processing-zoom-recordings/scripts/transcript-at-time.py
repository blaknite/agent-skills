#!/usr/bin/env python3
"""Show transcript cues around one or more timestamps.

Usage: python3 transcript-at-time.py TRANSCRIPT.vtt MM:SS [MM:SS ...]

Each timestamp prints cues from 30 seconds before to 30 seconds after.
"""

import re
import sys


def ts_to_seconds(ts):
    parts = ts.split(":")
    if len(parts) == 3:
        h, m, s = parts
        return int(h) * 3600 + int(m) * 60 + float(s)
    elif len(parts) == 2:
        m, s = parts
        return int(m) * 60 + float(s)
    else:
        return float(parts[0])


vtt_path = sys.argv[1]
targets = [ts_to_seconds(t) for t in sys.argv[2:]]

with open(vtt_path) as f:
    content = f.read()

cues = re.findall(
    r"(\d{2}:\d{2}:\d{2}\.\d+) --> \d{2}:\d{2}:\d{2}\.\d+\n(.+?)(?=\n\n|\Z)",
    content,
    re.DOTALL,
)

WINDOW = 30  # seconds of context either side

for target in targets:
    m, s = int(target // 60), target % 60
    print(f"=== {m:02d}:{s:04.1f} ± {WINDOW}s ===")
    for start_str, text in cues:
        t = ts_to_seconds(start_str)
        if target - WINDOW <= t <= target + WINDOW:
            tm, ts_ = int(t // 60), t % 60
            line = text.strip().replace("\n", " ")
            if len(line) > 120:
                line = line[:117] + "..."
            print(f"  {tm:02d}:{ts_:05.2f}  {line}")
    print()
