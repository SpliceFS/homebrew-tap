# Contributing to the SpliceFS Homebrew tap

This repository holds two Homebrew formulas, `splicefs-server` and `splicefs-client`, and
the workflows that test them.

## Before you start

Open an issue first for anything larger than a correction, so the approach can be agreed
before work is spent on it.

## Development setup

The formulas are tested only by the Tests workflow, which needs macOS on Apple silicon. To
check a change on your own Mac, tap a clone of this repository and run what the workflow runs:

```sh
brew style splicefs/tap/splicefs-server splicefs/tap/splicefs-client
brew audit --strict splicefs/tap/splicefs-server splicefs/tap/splicefs-client
brew install splicefs/tap/splicefs-server splicefs/tap/splicefs-client
brew test splicefs/tap/splicefs-server splicefs/tap/splicefs-client
```

Check the Ruby syntax of a formula without Homebrew with `ruby -c Formula/<name>.rb`.

## Branches

SpliceFS uses trunk development. There is one long-lived branch, `main`.

- `main` is protected: no direct pushes, no force pushes, no deletion, and CI must pass before
  a merge.
- Every change is a pull request into `main` from its own branch. Name the branch
  `feature/<name>`, `bug/<name>` or anything else that describes the change.
- A pull request merges with one merge commit. Squash and fast-forward merges are off.
- The tap is not versioned. The formulas name the versions of the programs.

## Standards

- A formula follows `brew style` and passes `brew audit --strict`.
- A formula never ships a configuration file. The programs refuse to start without one, and
  the user owns it.
- A formula builds with the same flags as the program's own `make build`.
- Every formula has a `test do` block that runs without a configuration or a network.
- A change to the workflows keeps every action pinned to a commit hash with the version in a
  comment.

## Commits and pull requests

- One purpose per commit. The message says what changed and why.
- A pull request targets `main`. CI must pass: Tests, CodeQL and dependency review.

## What CI checks

| Workflow | What it does |
| --- | --- |
| Tests | style, strict audit, install of the released versions and `brew test`, on macOS arm64, weekly as well |
| Security | CodeQL, and dependency review on pull requests |
| Scorecard | OpenSSF Scorecard, published weekly and on every push |

## Releases

When a program is released, `scripts/update-formulas.sh` rewrites the `url` and `sha256`
lines of its formula. Nothing else in the formula changes.

## License

By contributing you agree that your contribution is licensed under the [MIT license](LICENSE).
