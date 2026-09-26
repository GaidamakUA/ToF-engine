# AGENTS.md

Guidance for coding agents working in this repository.

## Project

This is a Godot 4 project for Tanks of Freedom II. Keep changes consistent with the existing GDScript style and scene/resource layout.

Use a local Godot 4 binary for validation. Set `GODOT_BIN` if Godot is not on `PATH`:

```sh
: "${GODOT_BIN:=godot}"
HOME=/private/tmp "$GODOT_BIN" --headless --path "$PWD" --quit
```

The normal headless load may print shutdown leak warnings. Treat a non-zero exit code, parser errors, stale resource paths, or new script errors as failures.

## Editing Rules

- Prefer small, focused changes that follow existing ownership boundaries.
- Do not revert user changes unless explicitly asked.
- Never stage changes or otherwise modify the Git index. Leave staging entirely to the user.
- Use `rg` for searches.
- Keep GDScript typed where practical, but avoid forcing awkward types where Godot APIs are genuinely variant-shaped.
- Do not hand-write generated Godot resource contents when Godot can save them correctly.
- Remove temporary migration/check scripts before finishing.

## Unified Template Architecture

All map templates should follow one boundary:

```text
template key -> shared MapObjectResource -> shared runtime scene
                                   \-> TileView preview
```

- Every value registered by `MapTemplates` must be a `MapObjectResource` subclass. Do not keep `PackedScene` compatibility entries in the template registry.
- `MapObjectResource` owns common static visual data: the main mesh and transform, shadow setting, optional reflection mesh, camera modifiers, and only the material overrides that differ from shared defaults.
- Rename `TileResource` to `TileResource` when completing the migration. It already describes ground, frame, decoration, terrain, and damage-layer tiles; those categories should use the same resource type.
- `TileResource` adds tile behavior: movement flags, sharing, vertical offset, damage-stage links, and other immutable tile configuration.
- Use a `DamageTileResource` subtype only for behavior that requires the shared damaged-tile runtime scene, such as explosion and smoke effects.
- `UnitResource` and `BuildingResource` add their category-specific static definitions. Heroes and NPC map templates are unit resources; side buildings are building resources.
- Runtime scenes are shared by behavior, not by template. Keep one configurable scene for normal tiles, damaged tiles, units, and buildings. A template-specific scene is not a map-template definition.
- `MapTemplates` is the single factory. It resolves a template key to its resource and configures the appropriate shared runtime scene. Callers must not inspect registry value types or instantiate template scenes themselves.
- `TileView` consumes `MapObjectResource` directly. It must create a mesh-only preview and must never instantiate a runtime scene.
- Do not add a `scene: PackedScene` escape hatch to `MapObjectResource`. If preview or runtime construction needs data, put that immutable data on the resource.

Static template data belongs under:

- `resources/ground`
- `resources/frame`
- `resources/decoration`
- `resources/terrain`
- `resources/damage`
- `resources/units`
- `resources/buildings`
- `resources/merged_meshes`

Keep runtime state on instances, fragments, or state objects. Shared resources are read-only definitions and must not be duplicated or mutated. Examples:

- Unit/building ownership and health are dynamic.
- Ability cooldowns and disabled flags live in `AbilityState`, not `Ability`.
- Unit HP, moves, attacks, level, experience, kills, team, AI pause, modifiers, tags, and ability states live in `UnitState`, not `UnitResource`.
- The selected template key, rotation, and presence of a damage-layer instance are dynamic map state.
- Particle emission and one-shot explosions are runtime behavior configured from a resource; particle nodes do not belong in resources.

## Damage Restoration

Preserve the two independent damage mechanisms:

1. Ground damage is a crater-style overlay in `MapTile.damage`. Its templates live in `resources/damage` and do not participate in terrain stage transitions.
2. Object damage replaces `MapTile.terrain` through a resource chain while preserving position and rotation.

Every destructible object uses these resource links:

```text
base.next_damage_stage_template      -> damaged
damaged.next_damage_stage_template   -> destroyed
damaged.base_stage_template          -> base
destroyed.base_stage_template        -> base
destroyed.next_damage_stage_template -> ""
```

Use stable template keys in these fields and in saved maps; do not store resource paths. `is_damageable()` means the next-stage key is non-empty. `is_restoreable()` means the base-stage key is non-empty.

Restore damage support in this order:

1. Create `TileResource`/`DamageTileResource` files for every entry currently in `_damage_templates`, `_city_templates`, and `_damaged_city_templates`. Preserve meshes, reflection meshes, transforms, shadow settings, camera modifiers, sharing/movement flags, stage links, and `is_smoking`.
2. Configure a shared damaged-tile scene from `DamageTileResource`. It owns the explosion and smoke nodes; `is_smoking` only selects whether the runtime instance emits smoke.
3. Replace all three registry groups with resource preloads while preserving every existing template key. Remove the `PackedScene` fallback only after all registry groups, including buildings, heroes/NPCs, special templates, and dummy templates, are resources.
4. Keep the transition in one path: resolve the next resource key, replace the terrain through `MapBuilder`, preserve Y rotation, mark the tile state modified, then trigger the new damaged-tile instance's explosion.
5. Keep editor cycling deterministic: base -> damaged -> destroyed -> base. Restoration always follows `base_stage_template`.
6. Keep ground damage placement in the `damage` fragment so map serialization and reload retain its template key and rotation independently from terrain.

Required damage checks:

- Every stage link resolves to a registered `TileResource` and no chain contains a cycle other than explicit restoration to base.
- A representative terrain and decoration advance base -> damaged -> destroyed and restore to base with rotation preserved.
- Collateral damage marks the map tile modified and survives save/reload.
- Ground damage survives save/reload without replacing terrain.
- Damaged runtime instances can play an explosion; destroyed instances emit smoke only when configured.
- Editor alternative cycling follows the same resource links as board collateral damage.

## Ability Rules

Abilities are resources and should behave like shared, mostly singleton definitions.

- Do not duplicate ability resources per unit/building instance.
- Do not put cooldown or disabled flags on `Ability`.
- Use `AbilityState` for per-source/per-ability runtime state.
- Prefer `AbilityState.new()` directly when a state object is needed.
- Keep `Ability` focused on static configuration and behavior hooks.

## Unit Rules

Regular side unit map templates are resources under `resources/units`.

- Use `UnitResource` for shared unit definitions: mesh, transform, side, stats, class, and ability resources.
- Use `UnitState` for per-instance mutable state.
- Do not duplicate `UnitResource` per placed unit.
- `BaseUnit.configure(UnitResource)` is the resource-to-instance boundary.
- Side-specific unit scenes may still exist as compatibility/view scenes for non-template usages, such as hero ability executor visuals.

## Mesh and Material Rules

Use shared material logic where possible.

- Normal ground/tile meshes use `res://assets/materials/arne32.tres`.
- Reflection meshes use `res://assets/materials/arne32_reflective.tres` through `GroundTile`.
- Avoid duplicating material overrides in many tile resources when the shared tile logic can apply them.
- Scenes with one material and multiple static mesh parts can be merged into one `ArrayMesh` under `resources/merged_meshes`.
- Preserve normal and reflection meshes separately. Add a more generic mesh-part model only if a real mixed-material template cannot be represented by those two slots.
- A preview material override uses `GeometryInstance3D.material_override`; do not also set every surface override to the same material.

## Template Map

Template registration lives in `res://scenes/map/templates.gd`.

- Keep the compiled registry typed as `Dictionary[String, MapObjectResource]`.
- Expose one resource lookup and one runtime-instantiation path. Do not maintain parallel scene and resource APIs.
- When replacing a scene with a resource, update all preloads and check for stale `res://scenes/...` references.
- Template previews, editor icons, portraits, and radial icons all use the same registered resource.

## Validation Checklist

Before finishing a non-trivial change:

```sh
git diff --check
rg -n "old/path/or/template/name" .
rg -n "_.*templates.*PackedScene|source\.scene|\.instantiate\(\).*template" scenes tests
: "${GODOT_BIN:=godot}"
HOME=/private/tmp "$GODOT_BIN" --headless --path "$PWD" --quit
```

Also load every changed resource and instantiate the shared runtime scenes when changing tile, damage, ability, or template code. Run the damage-chain checks above before removing legacy scenes.
