# Skyrail: Echoes of the Overgrowth

An original, small 3D movement-platformer prototype built with procedural low-poly geometry in Godot 4.3. You play a courier crossing floating gardens, restoring a wind beacon and exploring for wind shards. It uses no third-party art, music, or sound assets.

## Run the project

1. Install **Godot 4.3** (or a compatible Godot 4.x release).
2. Download or clone this repository and open `project.godot` in Godot.
3. Press **F6** to run the current scene or **F5** to run the project.
4. Choose **Play** on the title screen.

The project uses the **Compatibility** renderer and procedural meshes, with no plugins or large textures. It is designed to be Chromebook-friendly, but performance has not been measured on Chromebook hardware.

## Controls

- **WASD / arrow keys**: move relative to the camera
- **Mouse**: look around (captured during play; press Esc to pause and release it)
- **Space**: jump; briefly hold for a higher jump
- **Shift**: air/ground dash
- **E**: start a nearby movement challenge or restore the beacon
- **R**: return to the latest checkpoint
- **Esc**: pause

## What is in this prototype

- A compact floating-island zone with a broad central route, elevated stepping-stone route, lower shard grotto, and a checkpoint-unlocked bridge.
- A third-person courier controller with acceleration/deceleration, air control, jump buffering, coyote time, variable jump height, dash cooldown, and a SpringArm camera for basic collision handling.
- A luminous rail, wind launch pads, collectible wind shards, checkpoint/respawn, three challenge starts, pause/title/options/controls/completion screens, master-volume and 30/60 FPS options.
- The wind beacon is the optional-independent main completion objective. Press **E** beside it.

## Tuning

Open `scripts/player_controller.gd`. The exported values at the top tune ground acceleration/deceleration, top speed, air control, jump force, gravity, coyote time, jump buffering, dash speed, duration, and cooldown.

## Browser export

The project is structured for Godot's Web export and uses the Compatibility renderer. Export templates must match the installed Godot version. Browser builds are produced only after the repository's Web export workflow completes successfully; a browser build is not claimed as verified by this README.

## Known limitations / testing status

This is a procedural prototype, not a fully playtested release. Desktop/browser execution and Chromebook FPS have not been independently verified here. Audio cues are not yet implemented; volume control is provided for future audio. Rail grinding is a simple proximity-based assist rather than a full spline controller. Challenge and collision behavior should be tested in the Godot editor and adjusted if needed.
