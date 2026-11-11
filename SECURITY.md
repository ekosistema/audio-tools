# Security policy

audio-tools reads, renames, converts and moves your files, so we take problems that could cost you data
or run unintended commands seriously.

## Supported versions

Security fixes are made on the **latest release** only.

| Version | Supported |
|---|---|
| 3.1.x | ✅ |
| older | ❌ please upgrade |

## What counts as a security issue

Please report privately if you find a way to:

- **lose or overwrite data** that the documented [safety model](docs/safety.md) says is protected (for example a
  file deleted permanently, an overwrite in the trash, or a destructive action under `--dry-run`),
- **run commands** through a crafted file name, path, argument or configuration value (injection),
- **read or write outside** the directories you pointed the tool at (path traversal, symlink tricks),
- **leak information** through temp files, logs or output,
- tamper with the installer (`install.sh`) or the release artifacts.

Ordinary bugs (wrong output, crashes without data loss) belong in a normal
[issue](https://github.com/ekosistema/audio-tools/issues/new/choose).

## How to report

Use GitHub's private reporting:

1. Go to the repository's **Security** tab.
2. Choose **Report a vulnerability**
   ([direct link](https://github.com/ekosistema/audio-tools/security/advisories/new)).

Please include the version (`audio-tools --version`), your OS and Bash version, the exact command, and the
smallest set of files that reproduces the problem. Do not open a public issue or post details elsewhere
until a fix is available.

## What to expect

This is a small, volunteer-maintained project, so these are goals, not guarantees:

- we acknowledge your report within a few days,
- we confirm whether we can reproduce it and tell you how we plan to fix it,
- we release a fix, then publish an advisory crediting you (if you want credit).

Thank you for helping keep everyone's audio safe. 🔒
