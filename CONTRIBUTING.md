# Contributing to audio-tools

Thanks for wanting to help. Whether it is a typo, a bug report, a new command or just a "this confused me",
you are welcome here. 🎧

Please be kind to each other: this project follows the [Code of Conduct](CODE_OF_CONDUCT.md).

## Ways to contribute

| You want to... | Do this |
|---|---|
| Report a bug | [Open an issue](https://github.com/ekosistema/audio-tools/issues/new/choose) with the bug template. The more exact the steps, the faster the fix. |
| Suggest a feature | Open a feature request. Tell us the problem first; the solution can come later. |
| Fix something small | Send a pull request straight away. |
| Build something big | Open an issue first so we can agree on the shape before you invest the time. |
| Report a security problem | Do **not** open a public issue. See [SECURITY.md](SECURITY.md). |

## Set up in five minutes

You need **Bash 4+**, **ffmpeg** (with `ffprobe`), [**bats**](https://github.com/bats-core/bats-core) and
[**ShellCheck**](https://www.shellcheck.net/).

```bash
git clone https://github.com/ekosistema/audio-tools.git
cd audio-tools
bash tests/setup.sh                  # installs bats and shellcheck (apt/npm)

bash bin/audio-tools --version       # runs straight from the checkout, no install needed
bats tests/bats/                     # the whole suite (~170 tests, a minute or so)
shellcheck -x install.sh bin/audio-tools lib/*/*.sh lib/cli/*/*.sh
```

On macOS install a recent Bash first (`brew install bash`). On Windows, work inside WSL.

Tests create their audio fixtures with ffmpeg and run in a temp directory. Anything that could delete
files stubs `gio`/`trash-put` and points `XDG_DATA_HOME` at a temp folder, so the suite never touches your
real trash. Please keep it that way.

## Finding your way around

```
bin/audio-tools        entry point
lib/cli/               dispatcher, commands/ (one file per command), ui/ (menu, tables, progress)
lib/core/              the actual work (convert, dedup, process, ...)
lib/io/                ffmpeg, filesystem, trash: the only code that touches the outside world
lib/utils/             colors/logging, exit codes, config
tests/bats/            test suites
docs/                  architecture, safety model, command template
```

The tour with a diagram is in [`docs/architecture.md`](docs/architecture.md).

### Adding a command

1. Create `lib/cli/commands/<name>.sh` from [`docs/command-template.md`](docs/command-template.md) and define
   `cmd_<name>()` (hyphens in the name become underscores in the function).
2. Put the real work in `lib/core/`, not in the command file.
3. Add tests in `tests/bats/`, and a line in the README's command table.

The dispatcher discovers the command by file name, so there is nothing to register.

## House rules

These keep a tool that deletes files trustworthy. Reviewers will check them.

- **Never `rm` user files.** Use `move_to_trash`. It is recoverable, never overwrites, and already respects
  `--dry-run`.
- **`--dry-run` means nothing changes**: no moves, copies, conversions, new folders or prompts. Add a test that
  snapshots the directory tree before and after.
- **Ask before destroying.** Use `confirm_prompt`. `--force` skips it; `--quiet` must not.
- **Write outputs atomically** (a `.part` file renamed on success). See `run_atomic`.
- **Quote everything.** File names have spaces, quotes, pipes and unicode. ShellCheck must pass with no
  warnings, and tests should include a nasty file name.
- **No new runtime dependencies.** ffmpeg and coreutils only; no `jq`, `bc` or Python.
- **JSON through `json_string`**, never by pasting raw strings into `printf`.
- **Colors through the palette** (`$GREEN`, `$E_RED`, ...), never raw escape codes, and print user text with
  `printf '%b%s'` rather than `echo -e`.
- **Exit codes** follow sysexits (`lib/utils/errors.sh`).
- **Stay in your layer**: `cli` may call `core`, `core` may call `io`, never the other way round.

## Tests

```bash
bats tests/bats/test_dedup.bats      # one file
bats -f "dry-run" tests/bats/        # tests whose name matches
```

- New behavior needs a test; a bug fix needs a test that fails without the fix.
- Prefer testing the real binary (`run bash bin/audio-tools ...`) over calling internals.
- If you change `--help`, update the golden file: `NO_COLOR=1 bash bin/audio-tools --help > tests/golden/help.txt`.

## Commits and pull requests

- Small, focused commits with a message in the style `type(scope): what changed`, for example
  `fix(dedup): actually move duplicates to the trash`. Common types: `feat`, `fix`, `docs`, `refactor`, `test`,
  `ci`, `chore`. Explain the *why* in the body.
- Branch from `main`, keep your branch rebased, and describe what and why in the pull request. The template has
  a checklist.
- User-visible changes go in [`CHANGELOG.md`](CHANGELOG.md) under `[Unreleased]`.
- CI (ShellCheck + bats on Linux and macOS) must be green.

## Releasing (for maintainers)

1. Pick the version ([SemVer](https://semver.org/)): fixes only is a patch, new backwards-compatible behavior is a
   minor, a breaking change is a major.
2. Update **`VERSION`**, the version badge in `README.md`, the `.TH` line of `man/audio-tools.1`,
   the version strings in `html/index.html`, and `tests/golden/help.txt`.
3. Move the `[Unreleased]` notes in `CHANGELOG.md` under the new version with its date.
4. Run the full suite, then tag: `git tag -a vX.Y.Z -m "audio-tools vX.Y.Z"` and push the tag.
5. Create a GitHub release from the tag, pasting the changelog section.

## Questions

Not sure where something belongs, or whether it is worth a PR? Open an issue and ask. A half-formed idea is
welcome. Thank you for making audio-tools better. 💜
