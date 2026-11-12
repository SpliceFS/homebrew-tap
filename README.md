# SpliceFS Homebrew tap

[![Tests](https://github.com/SpliceFS/homebrew-tap/actions/workflows/tests.yml/badge.svg)](https://github.com/SpliceFS/homebrew-tap/actions/workflows/tests.yml)
[![Security](https://github.com/SpliceFS/homebrew-tap/actions/workflows/security.yml/badge.svg)](https://github.com/SpliceFS/homebrew-tap/actions/workflows/security.yml)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/SpliceFS/homebrew-tap/badge)](https://scorecard.dev/viewer/?uri=github.com/SpliceFS/homebrew-tap)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

The Homebrew formulas for [SpliceFS](https://splicefs.org) on macOS: `splicefs-server`
(the program `splicefsd`) and `splicefs-client` (the program `splicefs`).

Apple silicon only. The formulas do not install on Intel Macs.

## Install

No release has been tagged yet, so the formulas build from the `develop` branch of each
program. Install with `--HEAD`:

```
brew install --HEAD splicefs/tap/splicefs-server
brew install --HEAD splicefs/tap/splicefs-client
```

Building needs Go, which Homebrew installs as a build dependency. After the first release
the plain commands will install the released version:

```
brew install splicefs/tap/splicefs-server
brew install splicefs/tap/splicefs-client
```

## Configure and start

Neither program runs without a `config.yaml` in its configuration folder. The formulas
create the folders but never a configuration file:

- Server: `$(brew --prefix)/etc/splicefs/server/config.yaml`
- Client: `$(brew --prefix)/etc/splicefs/client/config.yaml`

The references are the [server configuration](https://github.com/SpliceFS/server/blob/develop/docs/configuration.md)
and the [client configuration](https://github.com/SpliceFS/client/blob/develop/docs/configuration.md).

Then start a program as a background service:

```
brew services start splicefs-server
brew services start splicefs-client
```

Logs are in `$(brew --prefix)/var/log/splicefsd.log` and `$(brew --prefix)/var/log/splicefs.log`.

On macOS the client mounts through the built-in NFS client. No extra software is needed.
Each mount target must be a folder you own, and it must exist before the client starts.
Set `cache.dir` to a folder you own, because the default `/var/cache/splicefs` is not
writable by a normal user.

## How the formulas are tested

The Tests workflow runs on an Apple silicon macOS runner for every push, pull request and
once a week. It makes the checkout the tap `splicefs/tap`, then runs `brew style`,
`brew audit --strict`, `brew install --HEAD` of both formulas, `brew test` of both, and
`brew services info` for both. The programs are not started, because they need a
configuration.

## License

MIT. See `LICENSE`.
