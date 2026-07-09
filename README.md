# Ambasaddor
<div style="width: 250px; height: 250px; display: flex; justify-content: center; align-items: center; margin: 0 auto; overflow: hidden;">
  <img src="https://i.imgur.com/3aXrc1P.png" style="width: 1000px; height: 1000px; max-width: none; object-fit: none; object-position: 50% 46%; transform: scale(0.45); transform-origin: center;">
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
