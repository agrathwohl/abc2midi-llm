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

## Upstream

The original abcMIDI package is maintained at [sourceforge](https://sourceforge.net/projects/abc/) and on the [runabc](https://ifdo.ca/~seymour/runabc/top.html) web page.
