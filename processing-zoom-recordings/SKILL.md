---
name: processing-zoom-recordings
description: "Processes Zoom meeting recordings: reads .vtt transcripts and .txt chat logs for conversation content, and extracts video frames (.mp4) using ffmpeg. Use when extracting spoken words from recorded Zoom calls, extracting slides, or working with Zoom recording files in .vtt or .mp4 formats."
---

# Processing Zoom Recordings

Works with Zoom meeting recording exports — transcripts (.vtt), video files (.mp4), and chat logs (.txt).

## Zoom Export File Conventions

Zoom exports a set of files per recording. Filenames follow the pattern:

```
GMT<DATE>-<TIME>_Recording.<EXT>
GMT<DATE>-<TIME>_Recording_<SUFFIX>_<RESOLUTION>.<EXT>
```

A single meeting typically produces:

| File | Content |
|------|---------|
| `…_Recording.transcript.vtt` | Auto-generated transcript (WebVTT format) |
| `…_RecordingnewChat.txt` | In-meeting chat log (public messages only) |
| `…_Recording_<RESOLUTION>.mp4` | **Gallery view** — grid of all participants' camera feeds |
| `…_Recording_as_<RESOLUTION>.mp4` | **Active speaker** — switches to current speaker; includes screen shares |
| `…_Recording_avo_<RESOLUTION>.mp4` | **Active video only** — speaker's camera feed without screen share overlay |

**For extracting slides or screen-share content, use the `as` (active speaker) file.** The gallery view is useful for seeing who was present but rarely contains readable screen content.

---

## Part 1: Transcripts (.vtt)

### WebVTT Format Reference

Zoom exports transcripts in the WebVTT (Web Video Text Tracks) format. The file structure is:

#### File Header

The file always starts with the string `WEBVTT` on the first line, followed by a blank line.

#### Cue Blocks

The rest of the file is a sequence of **cue blocks**, each separated by a blank line. A cue block has three parts:

```
SEQUENCE_NUMBER
START_TIMESTAMP --> END_TIMESTAMP
Speaker Name: Spoken text content
```

**Example:**

```
1
00:00:04.790 --> 00:00:08.460
Lucas Wilson-Richter: Later, for what is sure to be a gold mine.

2
00:00:09.480 --> 00:00:11.110
Lucas Wilson-Richter: of,

3
00:00:18.960 --> 00:00:20.210
Mark Wolfe: Not a problem.
```

#### Key characteristics

1. **Cue identifiers** are sequential integers (`1`, `2`, `3`, …).
2. **Timestamps** use `hh:mm:ss.ttt` format (hours, minutes, seconds, milliseconds), separated by ` --> `.
3. **Speaker attribution** is inline in the payload text as `Speaker Name: spoken text`. This is Zoom's convention — the WebVTT spec defines a `<v>` voice tag for this purpose, but Zoom does not use it.
4. **Cues are short fragments**, typically a few seconds each. A single sentence is often split across multiple consecutive cues from the same speaker.
5. **Automatic transcription is imperfect** — expect misspellings, misheard words, missing punctuation, and fragmented sentences. Proper nouns, technical jargon, and acronyms are frequently mangled.

### How to Read Transcripts

#### Step 1: Read the raw file

Use the `Read` tool. For large transcripts, read in chunks using `read_range`.

#### Step 2: Parse into structured data

When processing the transcript mentally, group consecutive cues from the same speaker into coherent utterances. A speaker turn ends when a different speaker's name appears.

#### Step 3: Handle transcription noise

- **Filler words and fragments**: Cues like `"of,"` or `"Yeah."` or `"Mmm…"` are conversational noise. They provide rhythm but rarely carry meaning.
- **Misheard words**: The transcription engine frequently mishears words. Use surrounding context to infer the intended meaning. Technical terms are especially prone to errors (e.g. "Bill Kite" for "Buildkite", "cube" for "Kube/k8s", "Katkins" for a person's name).
- **Incomplete sentences**: Speakers often start a thought, pause, and continue in the next cue or abandon it entirely. Reconstruct meaning from the flow.

#### Step 4: Extract meaningful content

When summarising or extracting information from a transcript:

- Focus on **what was decided, demonstrated, or explained** — not the conversational back-and-forth.
- Identify **action items** (things someone said they'd do or suggested doing).
- Note **key technical details**: tool names, commands, URLs, configuration values, architecture decisions.
- Ignore meta-conversation about the recording itself, pleasantries, and tangential banter unless it contains relevant context.

### Transcript Tips

- To identify all speakers in a transcript, run:
  ```bash
  grep -vE -e '^[[:space:]]*$' -e '^[0-9]+\r?$' -e '^WEBVTT' -e '^([0-9]{2}:){2}[0-9]{2}\.[0-9]*' TRANSCRIPT.vtt | sed 's/:.*//' | sort -u
  ```
  This filters out blank lines, sequence numbers, the header, and timestamps — leaving only speaker lines — then strips everything from the first colon onwards and deduplicates.
- Timestamps are useful for referencing specific moments but are not needed for content extraction.
- If the transcript is very long, read it in sections (e.g. 500 lines at a time) and build up understanding incrementally rather than trying to consume it all at once.

---

## Part 2: Extracting Video Frames (.mp4)

Uses ffmpeg to extract still frames from Zoom video recordings.

### Extract a single frame at a specific timestamp

```bash
ffmpeg -ss TIMESTAMP -i INPUT.mp4 -frames:v 1 output.png
```

- `-ss TIMESTAMP` — seek to this position before reading input. Use `hh:mm:ss` or `hh:mm:ss.mmm` format (e.g. `00:05:30` for 5 minutes 30 seconds).
- `-frames:v 1` — output exactly one video frame.
- Placing `-ss` **before** `-i` uses input seeking (fast, seeks to nearest keyframe). Place it **after** `-i` for frame-accurate seeking (slower but precise).

**Example — grab what's on screen at 12 minutes 45 seconds:**

```bash
ffmpeg -ss 00:12:45 -i GMT20260323-033358_Recording_as_1918x1074.mp4 -frames:v 1 slide_12m45s.png
```

### Extract frames at regular intervals

```bash
ffmpeg -i INPUT.mp4 -vf "fps=RATE" output_%04d.png
```

- `fps=1` — one frame per second
- `fps=1/5` — one frame every 5 seconds
- `fps=1/10` — one frame every 10 seconds
- `fps=1/30` — one frame every 30 seconds
- `fps=1/60` — one frame every 60 seconds

The `%04d` placeholder produces zero-padded sequence numbers (`0001`, `0002`, …).

**Example — one frame every 10 seconds:**

```bash
ffmpeg -i recording.mp4 -vf "fps=1/10" frames/frame_%04d.png
```

### Extract keyframes only

```bash
ffmpeg -i INPUT.mp4 -vf "select=eq(pict_type\,I)" -vsync vfr output_%04d.png
```

- `select=eq(pict_type\,I)` — selects only I-frames (keyframes). The backslash before the comma is required in shell.
- `-vsync vfr` — variable frame rate output; prevents ffmpeg from duplicating frames to fill gaps.

Keyframe extraction is **fast** (no full decode needed) and produces frames at natural scene-change boundaries, which is useful for capturing slide transitions in screen-share recordings.

### Extract frames within a time range

```bash
ffmpeg -ss START -to END -i INPUT.mp4 -vf "fps=1/5" output_%04d.png
```

- `-ss START` — start time
- `-to END` — end time (or use `-t DURATION` for a duration in seconds)

**Example — one frame every 5 seconds between the 10-minute and 20-minute marks:**

```bash
ffmpeg -ss 00:10:00 -to 00:20:00 -i recording.mp4 -vf "fps=1/5" segment_%04d.png
```

### Choosing a Strategy

| Goal | Command | Notes |
|------|---------|-------|
| Grab a specific moment | Single frame at timestamp | Use timestamps from the transcript |
| Capture all slides in a presentation | Keyframes only | Slide transitions produce keyframes; far fewer frames than interval-based extraction |
| Survey the whole meeting | Interval (e.g. every 30s) | Good for a visual overview; produces many files for long meetings |
| Detailed capture of a segment | Interval within a time range | Combine `-ss`/`-to` with `fps=` to focus on a specific portion |

### Video Frame Tips

- **Use the transcript for timestamps.** Match spoken content to timestamps in the `.vtt` file, then extract frames at those timestamps to capture what was on screen.
- **Create an output directory first.** When extracting many frames, create a dedicated directory and use a path prefix: `frames/frame_%04d.png`. ffmpeg will not create directories for you.
- **PNG vs JPEG.** Use `.png` for lossless quality (good for reading text in slides). Use `.jpg` for smaller file sizes when visual fidelity is less important. Add `-q:v 2` for high-quality JPEG output.
- **Overwrite protection.** ffmpeg prompts before overwriting existing files. Add `-y` to overwrite without prompting (useful in scripts).
- **Screen-share recordings have low motion.** Zoom's screen-share encoding uses long intervals between keyframes when the screen is static. Keyframe extraction works well here because transitions (new slides, switching apps) force new keyframes.
- **Speaker view recordings have high motion.** Camera feeds change constantly, producing many keyframes that are less meaningful. Interval-based extraction is usually better for these.
- **Use `look_at` before cropping.** When you need to crop a specific region from an extracted frame, use the `look_at` tool first to identify the pixel coordinates of the content you want. Ask it to list visible elements and their approximate y-coordinates. This avoids trial-and-error guessing of crop coordinates.

---

## Part 3: Chat Logs (.txt)

### Chat Log Format Reference

Zoom exports in-meeting chat as a plain text file. This format is not officially documented by Zoom — the following is derived from observation of exported files.

#### Line format

Each message is a single line with three tab-separated fields:

```
TIMESTAMP\tSender Name:\tMessage text
```

- **Timestamp** uses `HH:MM:SS` format (no milliseconds). This is the elapsed time from the start of the meeting, not wall-clock time.
- **Fields are separated by literal tab characters** (`\t`), not spaces.
- **Sender name** has a trailing colon before the tab.
- **Line endings** are `\r\n`.

**Example:**

```
00:05:11	Lucas Wilson-Richter:	Playground: https://playground.buildkite.dev/
00:07:20	Sean Waller:	The annoying thing about wireguard is NxM mesh means a bajillion keys needing to be shared
```

#### Multi-line messages

Longer messages or replies continue on subsequent lines without a timestamp prefix. A blank line separates the header line from the continuation text:

```
00:10:44	Sean Waller:	Replying to "Sean your audio is a..."

I'm on Juli's desk, just switched to his better mic
```

#### Reactions and replies

- **Reactions** appear as: `Reacted to "truncated quote..." with <emoji>`
- **Replies** appear as: `Replying to "truncated quote..."` followed by the reply text on continuation lines.

**Example:**

```
00:09:59	Lucas Wilson-Richter:	Reacted to "Sean your audio is a..." with 🎤
00:10:44	Sean Waller:	Replying to "Sean your audio is a..."

I'm on Juli's desk, just switched to his better mic
```

#### Key characteristics

1. **Only public messages** are included. Private/direct messages sent during the meeting are not saved to the cloud recording chat file.
2. **Timestamps are meeting-relative**, not wall-clock times. They correspond to the elapsed time in the recording.
3. **The chat file complements the transcript.** Participants often drop URLs, technical details, and corrections into chat that are not captured in the spoken transcript.

### Chat Log Tips

- To identify all chat participants, run:
  ```bash
  grep -E '^([0-9]{2}:){2}[0-9]{2}	' CHAT.txt | cut -f2 | sed 's/:$//' | sort -u
  ```
  This matches lines starting with an `HH:MM:SS` timestamp followed by a tab (skipping continuations that happen to start with digits), extracts the tab-delimited sender field, strips the trailing colon, and deduplicates.
- **Extract URLs from the chat log.** Chat messages frequently contain links that provide context for the spoken discussion. Use `grep -oE 'https?://[^ ]+' CHAT.txt` to extract all URLs.
- **Cross-reference with the transcript.** Chat timestamps align with transcript timestamps — use them to correlate chat messages with what was being discussed at that moment.
- **Prefer URLs from the chat log when adding links.** If you are trying to add a link to supplementary material and there is a URL in the chat log that looks relevant, then use it.
  - Relevant links tend to be posted near in time to the matter under discussion, or contain key words that appear in the transcript at about the same time.
  - You should also pay attention to the full text of the message where the URL appeared. 
  - Links to .gif files, or tenor.com, or giphy, are unlikely to be relevant.
  - Messages that received reactions like 🙏, 👍 or 💡 are likely to be particularly helpful.

---

## Part 4: Identifying Significant Moments

When processing a recording, identify moments that stand out — these are candidates for featuring in summaries, extracting as screen grabs, or clipping as short video segments.

### Categories of Significant Moments

#### Topic transitions

The conversation shifts from one subject to another. Signalled by phrases like "So, the first thing we need to do is…", "Alright, so…", "Let's…". These mark natural segment boundaries and are useful for structuring a summary into sections.

#### Demonstrations beginning

Someone starts showing something on screen — a UI, a terminal, a dashboard. Signalled by narration of what's visible: "If we go here…", "Let me show you…", "So we've got…" followed by description of on-screen content. These are prime candidates for screen grabs from the active-speaker (`as`) video.

#### Problem discoveries

An issue is identified live during the session. These tend to follow a distinctive pattern: observation ("it's stopped updating") → question ("why is it working so hard?") → explanation ("the liveness checks are in the same buffer as client requests"). The explanation moment is usually the most valuable to capture.

#### Explanatory moments

Someone gives a clear, coherent explanation of how something works — a system, a tool, a design decision. Often the densest information per second in the recording. Usually delivered as a long uninterrupted run from one speaker. Good candidates for pull quotes or detailed summary sections.

#### Emotional peaks

Exclamations, laughter, surprise — "Oh!", "Love it", "That's cool". These often coincide with visually interesting moments (something appeared on screen, something broke unexpectedly, a result was surprising). Worth checking the video at these timestamps.

#### Recap and summary moments

Participants step back and summarise what they've seen, done, or concluded. High information density, often near the end of a topic or the end of the meeting. Good source material for summary bullet points and action items.

### Detection Heuristics

When reading through a transcript, watch for these signals:

| Signal | What it suggests | Example |
|--------|-----------------|---------|
| Long uninterrupted run from one speaker | Explanation or demonstration | 10+ consecutive cues from the same person |
| Rapid question–answer exchanges | Clarification of something important | Short cues alternating between two speakers |
| Temporal gaps between cues | Screen activity, navigation, or thinking | Gap of several seconds with no speech |
| New technical terms appearing | Topic shift | Vocabulary not seen in preceding cues |
| Exclamations or emotional language | Something noteworthy just happened | "Oh!", "Love it", "That's interesting" |
| Imperative/future-tense statements | Action items or plans | "I'm gonna…", "We need to…", "Let's…" |
| Past-tense summaries | Recap of findings | "So we found…", "What we saw was…" |

### Finding Structured Segments

When extracting information for documentation, not all parts of a recording are equally useful. Segments where one person speaks at length tend to contain more structured, authoritative information — explanations, presentations, demonstrations — compared to rapid back-and-forth discussion. Two techniques help locate these segments.

#### Speaker change rate analysis

Count the number of speaker changes per minute across the transcript. Stretches with few or no speaker changes indicate a single person holding the floor — likely presenting, demonstrating, or explaining something in a structured way. These segments are the richest source of material for documentation.

Use the bundled scripts to perform this analysis. Do not generate new code — use these scripts directly.

**List every speaker change with timestamp:**

```bash
python3 scripts/speaker-changes.py TRANSCRIPT.vtt
```

**Show a timeline chart of speaker change rate and identify low-change stretches:**

```bash
python3 scripts/speaker-change-rate.py TRANSCRIPT.vtt [TERM_WIDTH]
```

**Show transcript cues around specific timestamps (±30 seconds):**

```bash
python3 scripts/transcript-at-time.py TRANSCRIPT.vtt MM:SS [MM:SS ...]
```

A rapid drop from high speaker-change rate to near-zero is a strong signal that someone has begun a presentation or demonstration.

#### Host identification (large meetings)

In large meetings with a designated host (e.g. a DOME in an ABC meeting, or a facilitator in a hangout), the host's utterances mark segment boundaries. Identify the host by looking for the person who:

- speaks first and last
- introduces other speakers by name
- uses handoff phrases: "over to you…", "throwing over to…", "next up, we have…", "back to you…"

Once you've identified the host, grep the transcript for their name and scan their lines for these handoff phrases. Each handoff marks the start of a new segment, and the speaker being introduced is the segment's presenter. This gives you a structural outline of the entire meeting without reading every line.

This technique is most useful for large, hosted meetings (all-hands, team syncs, engineering hangouts). Smaller meetings — two or three people in an informal discussion — don't usually have a host or distinct presentations, so the transcript-level heuristics from the Detection Heuristics table above are more applicable there.

### Choosing an Output Format

| Moment type | Best format | Why |
|-------------|-------------|-----|
| Demonstration beginning | Screen grab (PNG) | Captures what was on screen; a single frame is often sufficient |
| Problem discovery (explanation) | Pull quote in summary | The spoken explanation is the valuable part |
| Topic transition | Section heading in summary | Provides structure |
| Emotional peak | Short video clip or screen grab | Visual context adds value; the reaction is part of the moment |
| Recap / summary | Bullet points in summary | Already concise; easy to extract directly |
| Explanatory moment | Detailed paragraph in summary | Needs enough space to preserve the explanation's structure |

---

## Part 5: Creating a Screenshot Gallery for a Time Span

When a segment of a recording contains a demonstration or presentation worth documenting visually, extract a series of frames at regular intervals, examine each one, and produce an indexed gallery. This is especially useful for demo segments identified via speaker change rate analysis (Part 4).

### Step 1: Identify the time span

Use the techniques from Part 4 to find a segment worth capturing. Note the start and end timestamps. Typical sources:

- A low-change stretch from `speaker-change-rate.py` where one person is demonstrating something.
- A range identified by reading the transcript around a significant moment.

### Step 2: Create an output directory

Create a dedicated directory for the frames. Name it descriptively — e.g. `frames-04/` if it corresponds to the fourth section of your output, or `frames-demo-hubble/` for a specific topic.

```bash
mkdir -p frames-04
```

### Step 3: Extract frames with ffmpeg

Extract frames from the **active speaker** (`as`) video at regular intervals across the time span. One frame every 10 seconds is a good default for demos — frequent enough to capture each step, sparse enough to keep the set manageable.

```bash
ffmpeg -y -ss START -to END -i INPUT_as_RESOLUTION.mp4 -vf "fps=1/10" OUTPUT_DIR/frame_%04d.png
```

**Example — 40 frames across a 6m42s demo:**

```bash
ffmpeg -y -ss 00:25:18 -to 00:32:00 \
  -i inputs/GMT20260320-033017_Recording_as_2560x1410.mp4 \
  -vf "fps=1/10" frames-04/frame_%04d.png
```

The `-y` flag overwrites without prompting. Frame numbering starts at `0001`.

### Step 4: Calculate timestamps for each frame

Frame N corresponds to `START + (N-1) × interval`. For a 10-second interval starting at 25:18:

- `frame_0001.png` → 25:18
- `frame_0002.png` → 25:28
- `frame_0003.png` → 25:38
- …and so on.

### Step 5: Examine frames and gather transcript context

For each frame, do two things:

1. **Examine the image** using `look_at`. Write a short description (≤10 words) of what's visible on screen.
2. **Find what was being said** at that timestamp using the bundled script:

   ```bash
   python3 scripts/transcript-at-time.py TRANSCRIPT.vtt MM:SS [MM:SS ...]
   ```

   Pick the cue closest to the frame's timestamp (within ±5 seconds). Condense it to a single short line with the speaker's name.

Process frames in batches of ~10 to be efficient — call `transcript-at-time.py` once per batch with all the timestamps, and examine images in parallel.

### Step 6: Write GALLERY.md

Create an `GALLERY.md` in the frames directory as a Markdown table with these columns:

| Column | Content |
|--------|---------|
| **Thumbnail** | Inline image reference: `![](frame_NNNN.png)` |
| **Frame** | Filename (e.g. `frame_0001.png`) |
| **Timestamp** | Meeting-relative time (e.g. `25:18`) |
| **Description** | ≤10-word summary of visible content |
| **Transcript Context** | Speaker name and condensed dialogue |

**Example row:**

```markdown
| ![](frame_0037.png) | frame_0037.png | 31:18 | Hubble UI web page beside k9s service description | Chris Atkins: with no .tailnet stuff, uses Tailscale's MagicDNS |
```

### Gallery Tips

- **Use a subagent** (the Task tool) for the examine-and-index step. The prompt should specify the frame directory, the timestamp formula, the transcript path, the `transcript-at-time.py` script path, and the output format. This keeps the main thread's context clean.
- **10-second intervals** are a good default for demos. Use 30 seconds for long presentations with slow-changing content, or 5 seconds for fast-paced UI walkthroughs.
- **Always use the `as` (active speaker) video.** The gallery view rarely has readable screen content.
- **Thumbnails render in most Markdown viewers** (GitHub, VS Code preview) but the table cells can be wide. This is acceptable — the visual index is worth it.
