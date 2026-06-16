# AGENTS.md

Guidance for coding agents working in this repository.

## Project

This is a Godot 4 project for Tanks of Freedom II. Keep changes consistent with the existing GDScript style and scene/resource layout.

Use this Godot binary for local validation:

```sh
HOME=/private/tmp "~/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot" --headless --path /Users/Personal/workspace/godot/ToF-engine --quit
```

The normal headless load may print shutdown leak warnings. Treat a non-zero exit code, parser errors, stale resource paths, or new script errors as failures.

## Editing Rules

- Prefer small, focused changes that follow existing ownership boundaries.
- Do not revert user changes unless explicitly asked.
- Use `rg` for searches.
- Keep GDScript typed where practical, but avoid forcing awkward types where Godot APIs are genuinely variant-shaped.
- Do not hand-write generated Godot resource contents when Godot can save them correctly.
- Remove temporary migration/check scripts before finishing.

## Resources vs Scenes

The project is moving static data out of scenes and into resources.

Static tile data belongs in resources:

- `resources/abilities`
- `resources/ground`
- `resources/frame`
- `resources/decoration`
- `resources/terrain`
- `resources/merged_meshes`

The shared ground tile scene is:

- `res://scenes/tiles/ground/ground_tile.tscn`
- `res://scenes/tiles/ground/ground_tile.gd`
- `res://scenes/tiles/ground/ground_tile_resource.gd`

`GroundTileResource` should contain reusable static data: meshes, reflection meshes, shadow settings, movement flags, vertical offsets, camera modifiers, and damage-stage template names.

Runtime state should not be stored in shared resources. Keep state on instances or in state objects. Examples:

- Unit/building ownership and health are dynamic.
- Ability cooldowns and disabled flags live in `AbilityState`, not `Ability`.
- Damage layer instances are dynamic map state.

Important boundary: leave damaged/destroyed city/decor scenes alone for now. They are still scene templates in `_damaged_city_templates` and should remain `PackedScene`s unless the user explicitly asks to migrate them.

## Ability Rules

Abilities are resources and should behave like shared, mostly singleton definitions.

- Do not duplicate ability resources per unit/building instance.
- Do not put cooldown or disabled flags on `Ability`.
- Use `AbilityState` for per-source/per-ability runtime state.
- Prefer `AbilityState.new()` directly when a state object is needed.
- Keep `Ability` focused on static configuration and behavior hooks.

## Mesh and Material Rules

Use shared material logic where possible.

- Normal ground/tile meshes use `res://assets/materials/arne32.tres`.
- Reflection meshes use `res://assets/materials/arne32_reflective.tres` through `GroundTile`.
- Avoid duplicating material overrides in many tile resources when the shared tile logic can apply them.
- Scenes with one material and multiple static mesh parts can be merged into one `ArrayMesh` under `resources/merged_meshes`.
- Be careful with reflective or mixed-material scenes: preserve normal mesh and reflection mesh separately.

## Template Map

Template registration lives in `res://scenes/map/templates.gd`.

- When replacing a scene with a resource, update all preloads and check for stale `res://scenes/...` references.

## Validation Checklist

Before finishing a non-trivial change:

```sh
git diff --check
rg -n "old/path/or/template/name" .
HOME=/private/tmp "~/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot" --headless --path ~/workspace/godot/ToF-engine --quit
```

Also instantiate or load targeted resources/scenes when changing shared tile, ability, or template code.
