# Ambasaddor
<div style="width: 250px; height: 180px; overflow: hidden; position: relative; margin: 0 auto; display: block;">
  <img src="https://i.imgur.com/3aXrc1P.png" style="position: absolute; width: 500px; max-width: none; top: -75px; left: -125px;">
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
