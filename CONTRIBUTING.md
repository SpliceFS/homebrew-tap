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
brew style splicefs/tap
brew audit --strict splicefs/tap/splicefs-server splicefs/tap/splicefs-client
brew install --HEAD splicefs/tap/splicefs-server splicefs/tap/splicefs-client
brew test --HEAD splicefs/tap/splicefs-server splicefs/tap/splicefs-client
```

Check the Ruby syntax of a formula without Homebrew with `ruby -c Formula/<name>.rb`.

## Branches

SpliceFS uses the gitflow branching model.

- `main` holds released code only. Every commit on it is a release and carries a version tag.
- `develop` is where work comes together. It is the default branch, and pull requests target it.
- `feature/<name>` branches start from `develop` and merge back into it by pull request.
- `release/<version>` branches start from `develop` when a release is prepared. They take only
  fixes and the changelog, and merge into `main` and back into `develop`.
- `hotfix/<version>` branches start from `main` for urgent fixes and merge into `main` and
  `develop`.

`main` and `develop` are protected: no direct pushes, no force pushes, no deletion, and CI
must pass before a merge.

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
- A pull request targets `develop`. CI must pass: Tests, CodeQL and dependency review.

## What CI checks

| Workflow | What it does |
| --- | --- |
| Tests | style, strict audit, install from `develop` and `brew test`, on macOS arm64, weekly as well |
| Security | CodeQL, and dependency review on pull requests |
| Scorecard | OpenSSF Scorecard, published weekly and on every push |

## Releases

When a program is tagged, a release job adds `url`, `sha256` and `version` to its formula.
Nothing else in the formula changes.

## License

By contributing you agree that your contribution is licensed under the [MIT license](LICENSE).
