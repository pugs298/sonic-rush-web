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

## Visual update

The courier now has a distinct original teal-and-amber wind-runner silhouette with expressive face details, swept leaf-like fins, a flying scarf, gloves, and trail boots. The stage receives procedural gardens, route inlays, wind arches, rotating turbines, layered floating-rock ribs, and distant clouds. These are original low-poly visualizations, not Sonic assets or a Sonic character model. Materials are shared and the dressing is mesh-only to keep the extra scene cost modest.

## Tuning and known limitations

Movement values are exported at the top of `scripts/player_controller.gd`. Stage dressing is generated in `scripts/stage_visuals.gd`. The game still uses simple prototype rail behavior and placeholder audio; no local Godot run, browser export, or Chromebook FPS test has been performed for this update.
