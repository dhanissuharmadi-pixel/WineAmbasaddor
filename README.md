# Ambasaddor
<img src="https://i.imgur.com/3aXrc1P.png" width="450">
A silly little project for me to get familiar with swift and macOs
A minimal, personal Wine-based launcher for running Windows games on macOS. Specifically, Running steam games.

## Dev quick start

```sh
swift build
swift run amb doctor    # Rosetta, macOS version, fd limits
```
Runtime data lives in `~/Library/Application Support/Ambassador/`:

```
runtimes/   pinned Wine builds, D3DMetal, DXVK/DXMT
bottles/    per-game prefixes, each with config.json + logs/
library.json
```
