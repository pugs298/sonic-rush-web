# Skyrail: Echoes of the Overgrowth

An original low-poly 3D movement platformer built with Godot 4.3. You play a teal wind courier exploring floating gardens and restoring an ancient beacon. All character and stage details are procedural original placeholders; this project uses no third-party art, music, or character models.

## Run

1. Install Godot 4.3 or compatible Godot 4.x.
2. Open `project.godot` in Godot.
3. Press **F5** and choose **Play**.

The project uses the **Compatibility** renderer and procedural meshes. It is designed to stay lightweight, but Chromebook performance has not been measured here.

## Controls

- **WASD / arrow keys**: move relative to camera
- **Mouse**: look around (captured during play; Esc pauses/releases)
- **Space**: jump (hold briefly for more height)
- **Shift**: dash
- **E**: interact
- **R**: return to checkpoint
- **Esc**: pause

## Visual direction

The game uses an original, bright open-zone adventure direction: large readable sky-island silhouettes, ancient wind-tech landmarks, dramatic route arches, airy ribbons, monoliths, and layered cloud banks. It aims for the broad, high-speed open-world feeling of modern platform adventures without reproducing Sonic Frontiers' characters, assets, UI, or exact visual designs. The teal-and-amber courier and floating garden setting remain original.

The expansion adds landmark-sized wind hoops, distant temple islands, wayfinder stones, elevated wind-current streaks, route gates, rock spires, floating glyphs and seed lights, and layered clouds. All new objects are procedural meshes, share materials, disable shadows, and use no collision bodies or dynamic lights. Compatibility-renderer and Chromebook performance have not been measured for this update.

## Tuning and known limitations

Movement values are exported at the top of `scripts/player_controller.gd`. Stage dressing is generated in `scripts/stage_visuals.gd` and `scripts/horizon_expansion.gd`. The game still uses simple prototype rail behavior and placeholder audio; run the Godot editor and test the full play path before treating this build as verified.
