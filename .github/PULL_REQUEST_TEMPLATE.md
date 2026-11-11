## What does this change?

<!-- A sentence or two. Link the issue it closes: "Closes #123". -->

## Why?

<!-- The problem it solves or the behavior it fixes. -->

## How was it tested?

<!-- Commands you ran, and the tests you added. A bug fix needs a test that fails without the fix. -->

## Checklist

- [ ] `bats tests/bats/` passes
- [ ] `shellcheck -x install.sh bin/audio-tools lib/*/*.sh lib/cli/*/*.sh` is clean
- [ ] New or changed behavior has tests (including a file name with spaces/quotes where relevant)
- [ ] Anything that deletes, moves or overwrites files uses `move_to_trash` / `confirm_prompt` and honours `--dry-run`
- [ ] Docs updated (`README.md`, `--help`, man page, `docs/`) and `tests/golden/help.txt` if `--help` changed
- [ ] `CHANGELOG.md` has an entry under `[Unreleased]` for user-visible changes
