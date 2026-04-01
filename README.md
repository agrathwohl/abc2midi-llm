# abcMIDI

abcMIDI is a package of programs written in C for handling [abc music notation](http://abcnotation.com/) files. The software was created by James Allwright in the early 1990s and is presently maintained by Seymour Shlien.

This fork adds new LLM-centric MIDI directives that apply biological/organic timing transformations to MIDI output, making machine-generated music breathe.

## Programs

- **abc2midi** — convert abc notation to MIDI
- **midi2abc** — create abc notation from a MIDI file
- **abc2abc** — transpose abc notation to another key signature
- **mftext** — create a text representation of a MIDI file
- **yaps** — produce PostScript from abc notation
- **midicopy** — copy parts of a MIDI file to a new MIDI file
- **abcmatch** — find common elements in a collection of abc tunes
- **midistats** — display statistics about a MIDI file

## Building

### With Nix (recommended)

```bash
nix develop
./configure
make
```

### Without Nix

Requires a C compiler (gcc or clang), GNU make, and autoconf.

```bash
./configure
make
```

The build produces all binaries in the project root directory.

## Usage

```bash
./abc2midi input.abc -o output.mid
```

See the [abc2midi guide](https://abcmidi.sourceforge.io) for full documentation of standard features.

## Directive Extensions

### %%PNEUMA — Temporal Liberation

Pneuma directives apply organic timing variations to MIDI output. Instead of every note landing on an exact grid, Pneuma makes the output breathe — jitter, drift, sinusoidal tempo modulation, rubato, and free time.

Place `%%PNEUMA` directives in the tune body. They take effect from that point forward in the track.

| Directive            | Parameters                      | Effect                                                                                                |
| -------------------- | ------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `%%PNEUMA humanize`  | `N` (integer ticks)             | Add random jitter of ±N ticks to note onsets                                                          |
| `%%PNEUMA heartbeat` | `V` (float, 0.0–1.0)            | Sinusoidal tempo modulation modeling respiratory sinus arrhythmia. Breathing cycle = 8 quarter notes. |
| `%%PNEUMA drift`     | `R` (float, e.g. 0.015)         | Cumulative random-walk timing drift per beat, soft-clamped at ±4% of a quarter note                   |
| `%%PNEUMA free`      | `start` or `end`                | Toggle free time mode: durations become proportional suggestions with ±20% random scaling             |
| `%%PNEUMA rubato`    | up to 16 space-separated floats | Per-beat stretch factors within the bar (e.g. `1.15 0.9 0.95 1.0`)                                    |

### Example

```abc
X:1
T:Pneuma Example
M:4/4
L:1/8
Q:1/4=120
K:C
%%PNEUMA humanize 12
%%PNEUMA heartbeat 0.04
%%PNEUMA drift 0.015
%%MIDI program 0
CDEF GABc | cBAG FEDC |
%%PNEUMA free start
C4 E4 | G4 c4 |
%%PNEUMA free end
%%PNEUMA rubato 1.15 0.9 0.95 1.0
CDEF GABc | cBAG FEDC |
```

Generate MIDI:

```bash
./abc2midi example.abc -o example.mid
```

### %%ENSEMBLE — Inter-Voice Timing Offset

ENSEMBLE adds micro-timing offsets between voices so independently generated parts sound like musicians playing together rather than a single quantized block. In a real ensemble, the bass anticipates slightly, the lead lags expressively, and the drummer anchors the grid.

Place `%%ENSEMBLE` directives in the tune header for global settings, and within voice sections for per-voice settings.

| Directive            | Parameters                     | Effect                                                                                       |
| -------------------- | ------------------------------ | -------------------------------------------------------------------------------------------- |
| `%%ENSEMBLE offset`  | `N` (signed integer ticks)     | Global default onset shift applied to all voices. Positive = late, negative = early.         |
| `%%ENSEMBLE jitter`  | `N` (integer ticks)            | Random per-note jitter of ±N ticks on top of voice offset. Stacks with Pneuma humanize.     |
| `%%ENSEMBLE voice`   | `N` (signed integer ticks)     | Per-voice constant offset. Negative = pushes beat (driving), positive = lays back (expressive). |

When both PNEUMA and ENSEMBLE are active:

```
final_onset = grid_position + pneuma_transforms + pneuma_humanize
              + ensemble_global_offset + ensemble_voice_offset + ensemble_jitter
```

### Example

```abc
X:1
T:Ensemble Example
M:4/4
L:1/8
Q:1/4=120
K:Dmin
%%ENSEMBLE jitter 4
[V:1 name="Lead"]
%%MIDI program 0
%%ENSEMBLE voice 8
DEFG ABcd | dcBA GFED |
[V:2 name="Bass"]
%%MIDI program 39
%%ENSEMBLE voice -6
D,4 A,4 | D,4 F,4 |
[V:3 name="Drums" clef=perc]
%%MIDI channel 10
%%ENSEMBLE voice 0
C4 D4 C4 D4 | C4 D4 C4 D4 |
```

### %%BREATH — Automatic Rest Insertion

BREATH inserts micro-rests at phrase boundaries so the piece breathes. LLM-generated output fills every beat relentlessly; BREATH separates phrases with brief silence.

| Directive        | Parameters          | Effect                                                                      |
| ---------------- | ------------------- | --------------------------------------------------------------------------- |
| `%%BREATH auto`  | `N` (integer ticks) | Enable breath insertion of N ticks at every bar line (default interval = 1) |
| `%%BREATH bars`  | `N` (integer)       | Insert breath only every N bars instead of every bar                        |
| `%%BREATH after` | `N` (integer ticks) | Also insert breath after notes whose duration exceeds N ticks               |
| `%%BREATH off`   |                     | Disable all breath insertion                                                |

### %%GRAVITY — Phrase-Level Weight

GRAVITY applies phrase-level dynamics so bars within a phrase have varying weight. Heavier openings, lighter middles, stretched endings — the shape of a spoken sentence applied to musical phrases.

| Directive          | Parameters                      | Effect                                                              |
| ------------------ | ------------------------------- | ------------------------------------------------------------------- |
| `%%GRAVITY phrase` | `N` (integer bars)              | Set phrase length to N bars                                         |
| `%%GRAVITY weight` | up to 16 space-separated floats | Velocity multiplier per bar within phrase (e.g. `1.15 1.0 0.9 0.85`) |
| `%%GRAVITY agogic` | up to 16 space-separated floats | Duration multiplier per bar within phrase (e.g. `1.05 1.0 1.0 0.95`) |
| `%%GRAVITY off`    |                                 | Disable gravity                                                     |

### %%ARTICULATE — Context-Aware Note Length

ARTICULATE adjusts note durations based on musical context. Repeated pitches are shortened, leaps are lengthened, phrase endings are sustained, and staccato notes are explicitly controlled. Factors compose multiplicatively when multiple conditions apply. Skips drum channel (ch 10) and only applies to standalone notes (not mid-chord).

| Directive                 | Parameters        | Effect                                                                 |
| ------------------------- | ----------------- | ---------------------------------------------------------------------- |
| `%%ARTICULATE auto`       |                   | Enable all rules with defaults (repeated=0.85, leap=1.1, phraseend=1.15, staccato=0.5) |
| `%%ARTICULATE repeated`   | `F` (float 0–2)  | Scale duration of repeated pitches by F (e.g. `0.8` = 80%)            |
| `%%ARTICULATE leap`       | `F` (float 0–2)  | Scale duration of notes after intervals > perfect 4th by F            |
| `%%ARTICULATE phraseend`  | `F` (float 0–2)  | Scale duration of notes before a rest or barline by F                  |
| `%%ARTICULATE staccato`   | `F` (float 0–1)  | Set staccato note duration as ratio of original (e.g. `0.5` = 50%)    |
| `%%ARTICULATE off`        |                   | Disable all articulation rules                                         |

### %%SPATIAL — Inter-Group Timing Offset

SPATIAL simulates physical distance between groups of voices by adding millisecond-scale delays converted to MIDI ticks. Groups are defined with single-letter names (A–Z) and assigned voices. Delays between groups are symmetric. Group A (index 0) is the reference group with zero delay; all other groups are offset relative to it. SPATIAL state is global — it persists across tracks and is never reset.

| Directive          | Parameters                        | Effect                                                                  |
| ------------------ | --------------------------------- | ----------------------------------------------------------------------- |
| `%%SPATIAL group`  | `X voices N,N,...` (letter + ints) | Define group X containing listed voice numbers (max 8 groups, 16 voices per group) |
| `%%SPATIAL delay`  | `X Y N` (two letters + int ms)    | Set N milliseconds delay between groups X and Y (symmetric)             |

### %%TRANSFORM — Cross-Voice Algorithmic Transformation

TRANSFORM reads note data from a source voice, applies a chain of algorithmic operations, and replaces the target voice's content with the result. This is a pre-generation pass that modifies the feature arrays before MIDI output. Operations are applied in order: fragment → retrograde → invert → pitch shift → time scale. Pitch values are clamped to 0–127. Requires both source and target to be specified.

| Directive                 | Parameters              | Effect                                                                  |
| ------------------------- | ----------------------- | ----------------------------------------------------------------------- |
| `%%TRANSFORM source`      | `N` (voice number)      | Set source voice to copy notes from                                     |
| `%%TRANSFORM target`      | `N` (voice number)      | Set target voice to replace with transformed notes                      |
| `%%TRANSFORM retrograde`  |                         | Reverse the note/rest sequence (bar lines stay in place)                |
| `%%TRANSFORM invert`      |                         | Mirror pitches around the inversion axis                                |
| `%%TRANSFORM invertaxis`  | `N` (MIDI pitch 0–127)  | Set inversion axis (default 60 = middle C)                              |
| `%%TRANSFORM fragment`    | `S E` (start/end bars)  | Extract only bars S through E from source (0-indexed)                   |
| `%%TRANSFORM pitchshift`  | `N` (semitones ±)       | Transpose all pitches by N semitones                                    |
| `%%TRANSFORM timescale`   | `F` (float)             | Scale all note/rest durations by factor F                               |
| `%%TRANSFORM delay`       | `N` (bars)              | Prepend N bars of whole-bar rests before transformed content            |
| `%%TRANSFORM off`         |                         | Disable transform (no operation performed)                              |

## Upstream

The original abcMIDI package is maintained at [sourceforge](https://sourceforge.net/projects/abc/) and on the [runabc](https://ifdo.ca/~seymour/runabc/top.html) web page.
