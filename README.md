# Cozy Sleeping Bag Timer

Stop counting minutes in your head. **Cozy Sleeping Bag Timer** shows exactly how your Cozy Sleeping Bag rest is going: when the next Well-Rested stack lands, how long your bonus lasts, and when you can use the bag again.

## Features

- **Resting bar**: a 3-minute bar with a mark at each minute, one per Well-Rested stack. Shows your current stack (`Resting 2/3`) and a countdown to the next one. It appears while you are in the bag and disappears when you get up.
- **Well-Rested timer**: your current XP bonus (+1% to +3%) and how long the buff has left.
- **Bag cooldown**: how long until the Cozy Sleeping Bag is ready again.
- **Stays out of the way**: only the rows that matter are shown, and the whole window hides when there is nothing to track.
- **Movable**: drag the window anywhere on screen.
- **Lightweight**: one small file, no libraries, no settings to configure.

## How it works

The resting bar starts when you use the bag and resyncs every time a new stack arrives. Moving, or a stack arriving late, counts as getting up and hides the bar. Once you reach 3/3 there is nothing more to gain, so the bar hides and the buff and cooldown timers remain.

## Commands

- `/sbt`: prints the addon's current state in chat. Useful if you want to report a problem.

## Notes

- Made for **World of Warcraft: Forever**.
- The buff is found by its English name, "Well-Rested", so non-English clients are not supported yet.
- Forever hides some auras from addons. Cozy Sleeping Bag Timer skips those safely instead of throwing errors.

## Feedback

Found a bug or have an idea? Leave a comment or open an issue. Please include the line `/sbt` prints.
