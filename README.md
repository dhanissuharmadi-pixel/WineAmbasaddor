# Ambasaddor
<div style="display: flex; justify-content: center; width: 100%;">
  <img src="https://imgur.com" width="450">
</div>
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
