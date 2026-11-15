# Security policy

This repository holds the Homebrew formulas that build and install SpliceFS on other
people's Macs. Problems here are treated as urgent.

## Reporting a vulnerability

Do not open a public issue for a security problem.

Report it privately through GitHub: open the repository's **Security** tab and choose
**Report a vulnerability**. Include what you ran, on which system, and what happened.

You can expect an acknowledgement within five working days. Once a fix is published, the
advisory is published and the reporter is credited unless they ask not to be.

## Scope

In scope: anything that lets a formula install or run code other than the SpliceFS source it
names, write files outside Homebrew's own folders, ship a configuration or a credential, or
start a service with more privileges than the program needs.

Problems in the programs themselves are reported in the
[server](https://github.com/SpliceFS/server) and
[client](https://github.com/SpliceFS/client) repositories.
