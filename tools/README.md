# Automated playtest

From the project root on macOS:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tools/playtest.gd -- --seed=20260920
```

Opens a game window, traverses a seeded floor, checks walls and exploration,
captures four screenshots, writes `playtest-output/report.json`, then exits.
Screenshots come from Godot's own viewport, not the computer desktop.
Output is ignored by Git. Use `--output=/absolute/path` after `--` for another
output folder. Change the seed to exercise different layouts.

Add `--headless` before `--path` to run logic checks without screenshots.
Use the graphical run for visual inspection; headless success does not validate
appearance. The test calls the gameplay movement method directly, so it does
not test physical keyboard input, mobile controls, or human playability.
