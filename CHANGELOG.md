# Changelog

All notable changes to this project are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project follows
[Semantic Versioning](https://semver.org).

## [Unreleased]

### Added

- The formulas `splicefs-server` and `splicefs-client` for macOS on Apple silicon, built from
  the `main` branch of each program until the first release. They install the commands
  only; no background service is defined.
- Tests, CodeQL, dependency review and OpenSSF Scorecard workflows.
- Trunk development: one branch, `main`.
- `make check` fails when a tracked file names a private machine, account or place, and the
  ignore rules cover programs built in place, editor leftovers and disk images.
