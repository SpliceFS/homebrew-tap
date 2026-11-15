# SpliceFS Homebrew tap

[![Tests](https://github.com/SpliceFS/homebrew-tap/actions/workflows/tests.yml/badge.svg)](https://github.com/SpliceFS/homebrew-tap/actions/workflows/tests.yml)
[![Security](https://github.com/SpliceFS/homebrew-tap/actions/workflows/security.yml/badge.svg)](https://github.com/SpliceFS/homebrew-tap/actions/workflows/security.yml)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/SpliceFS/homebrew-tap/badge)](https://scorecard.dev/viewer/?uri=github.com/SpliceFS/homebrew-tap)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

The Homebrew formulas for [SpliceFS](https://splicefs.org) on macOS: `splicefs-server`
(the program `splicefsd`) and `splicefs-client` (the program `splicefs`).

Apple silicon only. The formulas do not install on Intel Macs.

## Install

```sh
brew install splicefs/tap/splicefs-server
brew install splicefs/tap/splicefs-client
```

The formulas install the latest released version of each program, and follow each new
release automatically. Building needs Go, which Homebrew installs as a build dependency.
To build the `main` branch of a program instead, add `--HEAD` to the command.

## Run

The formulas install the two commands and nothing else. They are not set up as background
services; how and when they run is up to you.

```sh
splicefsd --config DIR
splicefs --config DIR mount
```

The references are the [server configuration](https://github.com/SpliceFS/server/blob/main/docs/configuration.md)
and the [client configuration](https://github.com/SpliceFS/client/blob/main/docs/configuration.md).

On macOS the client mounts through the built-in NFS client. No extra software is needed,
and it does not need root.

## How the formulas are tested

The Tests workflow runs on an Apple silicon macOS runner for every push, pull request and
once a week. It makes the checkout the tap `splicefs/tap`, then runs `brew style`,
`brew audit --strict`, `brew install` of both formulas and `brew test` of both.

## License

MIT. See `LICENSE`.
