#!/usr/bin/env python3
"""Show speaker change rate per minute as a timeline chart, and list
low-change stretches that likely contain structured explanations.

Usage: python3 speaker-change-rate.py TRANSCRIPT.vtt [TERM_WIDTH]
"""

import os
import re
import sys

vtt_path = sys.argv[1]
term_width = int(sys.argv[2]) if len(sys.argv) > 2 else os.get_terminal_size().columns

with open(vtt_path) as f:
    content = f.read()

cues = re.findall(
    r'(\d{2}:\d{2}:\d{2}\.\d+) --> (\d{2}:\d{2}:\d{2}\.\d+)\n(.+?)(?=\n\n|\Z)',
    content,
    re.DOTALL,
)


def ts(t):
    h, m, s = t.split(":")
    return int(h) * 3600 + int(m) * 60 + float(s)


# Count speaker changes
prev = None
changes = []
for start, end, text in cues:
    speaker = text.split(":")[0].strip()
    if prev and speaker != prev:
        changes.append(ts(start))
    prev = speaker

duration = ts(cues[-1][1])

# Bucket into 1-minute bins
num_buckets = int(duration // 60) + 1
buckets = [0] * num_buckets
for t in changes:
    b = int(t // 60)
    if b < num_buckets:
        buckets[b] += 1

max_val = max(buckets)

# Count cues per speaker
speaker_cues = {}
for start, end, text in cues:
    speaker = text.split(":")[0].strip()
    speaker_cues[speaker] = speaker_cues.get(speaker, 0) + 1

basename = os.path.basename(vtt_path)
print(f"Speaker changes — {basename} ({int(duration // 60)}m)")
print(f"Total speaker changes: {len(changes)}")
for speaker, count in sorted(speaker_cues.items(), key=lambda x: -x[1]):
    print(f"  {speaker}: {count} cues")
print()

# Timeline chart
y_label_width = 5
chart_width = min(term_width - y_label_width, num_buckets)

# If more buckets than chart width, aggregate
if num_buckets > chart_width:
    ratio = num_buckets / chart_width
    display_buckets = []
    for i in range(chart_width):
        start_b = int(i * ratio)
        end_b = int((i + 1) * ratio)
        display_buckets.append(sum(buckets[start_b:end_b]))
    display_max = max(display_buckets)
else:
    display_buckets = buckets
    display_max = max_val
    chart_width = num_buckets

for row in range(display_max, 0, -1):
    label = f"{row:>3d} " if row % 2 == 0 or display_max <= 5 else "    "
    line = "▏"
    for b in range(chart_width):
        line += "█" if display_buckets[b] >= row else " "
    print(label + line)

print("  0 ▏" + "─" * chart_width)

# Time labels
tick_line = "     "
for i in range(chart_width):
    if num_buckets <= chart_width:
        minute = i
    else:
        minute = int(i * num_buckets / chart_width)
    if minute % 5 == 0 and (i == 0 or tick_line[-1] != "│"):
        tick_line += "│"
    else:
        tick_line += " "
print(tick_line)

labels = "    "
for i in range(0, chart_width, 5):
    if num_buckets <= chart_width:
        minute = i
    else:
        minute = int(i * num_buckets / chart_width)
    labels += str(minute).ljust(5)
print(labels)
print(" " * (term_width // 2 - 8) + "minutes")
print()

# Find low-change stretches
print("Low-change stretches (≤1 change/min for 2+ consecutive minutes):")
print()
i = 0
while i < num_buckets:
    if buckets[i] <= 1:
        start = i
        while i < num_buckets and buckets[i] <= 1:
            i += 1
        length = i - start
        if length >= 2:
            total_changes = sum(buckets[start:i])
            print(
                f"  {start:02d}:00 – {i:02d}:00  ({length} min, {total_changes} speaker changes)"
            )
    else:
        i += 1
