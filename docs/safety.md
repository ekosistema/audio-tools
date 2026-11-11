# Safety model

audio-tools is meant to be run on folders you care about, so the rules below are guarantees, not
suggestions. Each one is covered by an automated test.

## 1. Nothing is deleted for good

Every command that removes a file (`remove short|long`, `dedup`, `search --operation delete`) moves it to
the trash through a single function, `move_to_trash`. It tries, in order:

| Platform | Order of attempts |
|---|---|
| macOS | `~/.Trash` |
| Linux and WSL | `gio trash`, then `trash-put`, then the [FreeDesktop Trash](https://specifications.freedesktop.org/trash-spec/latest/) in `$XDG_DATA_HOME/Trash` (default `~/.local/share/Trash`) |
| Anything else, or if all of the above fail | a `to_delete/` folder next to the files |

The FreeDesktop fallback writes the same `files/` and `info/*.trashinfo` pair a desktop environment
would, with the percent-encoded original path and the deletion date, so you can **restore** the file
from a file manager, `gio trash --restore` or `trash-restore`.

If two files with the same name end up in the trash, the second becomes `name_2.ext`. Nothing is
overwritten.

> WSL note: files on `/mnt/c` or `/mnt/d` go to that drive's own trash (`.Trash-<uid>` at the drive
> root) when `gio` is installed, or to your Linux home trash otherwise.

## 2. It asks before destroying anything

Destructive commands require you to type `yes`. Anything else (`y`, `no`, an empty line) cancels.

- `--force` skips the question. The files still go to the trash.
- `--quiet` hides messages but **never** skips the question.
- With no one to answer (cron, CI, a closed pipe) the command exits with status `64` and a hint to use
  `--force`. It does not guess.

## 3. `--dry-run` is a promise

With `--dry-run` no file is moved, converted, created or deleted, and no confirmation is asked. You see what
would happen, in yellow:

```console
$ audio-tools remove short --threshold 2 --dry-run
  would move to trash: ./click.wav
[INFO] [dry run] Would delete 1 short files
```

The flag works before or after the command (`audio-tools --dry-run dedup` is the same as
`audio-tools dedup --dry-run`). Deletions are covered in `move_to_trash` itself, so a new command cannot
forget it, and a dry run does not even create an empty output folder. The one exception is the `config`
command, which edits your settings file and always acts.

## 4. No half-written files

`convert`, `normalize` and `trim-silence` write to `<name>.part.<ext>` and rename the file only when ffmpeg
finishes successfully. If a run fails or you press Ctrl-C, the real file name is never a truncated file that a
later run would treat as finished (after Ctrl-C a stray `*.part.*` file may remain; it is ignored by every scan
and safe to delete). When a conversion fails, the last line of ffmpeg's error is printed (the whole log with
`--verbose`).

## 5. Your audio is not silently degraded

Sample rate and channel layout are preserved by default. A 96 kHz FLAC stays 96 kHz and a mono recording
stays mono. The only exceptions are encoder limits (MP3 is capped at 48 kHz and 2 channels, AAC at 96 kHz)
or when you ask for something else with `AUDIO_TOOLS_SAMPLE_RATE` / `AUDIO_TOOLS_CHANNELS`.

## 6. Which file does `dedup` keep?

Files are compared by SHA256, so only **byte-identical** copies are duplicates. In each group the file whose
path sorts first is kept; the others go to the trash. Use `find-dupes` to review the groups without
changing anything.

## Reporting a safety problem

If you find a way to lose data that these rules do not prevent, please follow [`SECURITY.md`](../SECURITY.md).
