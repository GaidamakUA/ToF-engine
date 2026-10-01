# ToF Engine development guide

ToF Engine is a Godot 4.7 fork of Tanks of Freedom II, written primarily in
typed GDScript. The current main scene is
`res://scenes/main_menu/main_menu.tscn`.

## Direction and compatibility

The bundled Tanks of Freedom II content is both the current playable game and
the reference implementation used while extracting a more general engine. The
work has three priorities:

1. Keep existing ToF II content and behavior working.
2. Improve performance, maintainability, and configuration boundaries.
3. Make content and rules replaceable enough for other Advance Wars–style
   games and original projects.

Tanks of Freedom 1 compatibility is exploratory. New engine boundaries should
make importing its content possible where practical, but code must not assume
that full compatibility already exists. Likewise, reusable APIs should follow
demonstrated modding needs rather than speculative abstraction.

## Project layout

- `assets/` contains imported art, audio, fonts, maps, translations, and the
  bundled campaigns.
- `campaign/` contains custom campaigns available to the local checkout.
- `resources/` contains reusable static game definitions such as abilities,
  units, terrain, ground tiles, decorations, frames, and merged meshes.
- `scenes/` contains runtime scenes and scripts for the board, map, editor,
  tiles, and user interface.
- `scripts/services/` contains project autoloads for settings, saves, campaign
  data, multiplayer, online services, audio, and scene changes.
- `tests/unit/` contains the GUT suite; `tests/fixtures/` contains test data.
- `tools/run_gut.sh` runs the tests headlessly.

## Runtime structure

The board uses a model-presenter-view split:

- `BoardModel` is the gameplay command surface. It owns rules and emits
  detached `BoardStateSnapshot` values plus value-only domain events.
- `BoardPresenter` owns selection, hover, targeting, and legal-highlight state,
  translates view controls into model commands, and turns snapshots/events into
  view calls. It queues updates while the view is presenting a previous update.
- `BoardView` is the Godot scene host at the existing board scene path. It
  captures input and owns nodes, audio, animation, cameras, and UI.
- `BoardAnimationPlayer` maps `BoardAnimation.Kind` values to view-owned action
  choreography and signals the presenter when timed playback has finished.

Headless callers use `BoardModel` directly. Save and network adapters are the
only boundaries that convert typed state to dictionaries.

The map follows a similar boundary. `MapModel` owns the 40×40 logical grid and
serialized data, `MapBuilder` places or removes runtime objects for the view, and
`MapLoader` handles current and legacy map data. Template names are registered
centrally in `res://scenes/map/templates.gd`.

`BoardModel` still stores map objects in scene-backed tile fragments during the
migration. This is an internal compatibility boundary: nodes never appear in
snapshots, commands, or domain events, and gameplay paths must not rely on the
scene tree, animation timing, audio, cameras, or UI.

## Static definitions and runtime state

Reusable definitions are shared resources so a mod or game package can replace
content without duplicating runtime state. Mutable state belongs to an
instance:

- `UnitResource` defines a unit's mesh, side, stats, class, sounds, camera
  offsets, and abilities. `BaseUnit.configure()` applies it to a runtime unit.
- `UnitState` stores HP, moves, attacks, level, experience, team, modifiers,
  scripting tags, AI pause state, and per-ability state.
- `Ability` defines shared configuration and behavior. `AbilityState` stores a
  source's cooldown and disabled flag.
- `TileResource` defines reusable ground meshes, movement properties,
  offsets, shadows, reflections, and damage-stage template names.

Do not duplicate these resources for each placed object, and do not put
runtime values into them. Map templates are registered resources and share
runtime scenes by behavior.

## TOF camera impostors

The fixed TOF camera renders eligible static terrain and frames as baked
`Sprite3D` impostors. Each eligible `MapObjectResource` owns a 2×2 texture with
views for rotations 0, 90, 180, and 270 degrees. Frames use adaptive bounds at
64 pixels per world unit and include the mesh's cast shadow when enabled. Each
eligible tile uses one alpha-blended billboard shifted toward the fixed TOF
camera along its view axis so the ground cannot clip it. Decorations and
standable terrain retain their meshes for correct unit depth, plus a
shadow-only billboard. The shift is applied in global space so tile rotation
cannot move it. The four atlas frames represent the tile's own rotation, not
different camera angles.

The impostors fully replace their source meshes at every TOF zoom level. AW and
Free camera modes continue to use the meshes, as does any resource without a
baked texture. Ground, ground damage, decorations, standable terrain, units,
capturable buildings, rotating objects, particles, and editor previews remain
3D. Source meshes are canonical;
generated compressed texture files live under
`res://assets/impostors/tof`. Resources store lazy texture paths so the template
registry does not load every baked sheet into GPU memory at startup. The `.res`
textures contain compressed mip levels. Baked TOF shadows are part of the
generated artwork and do not follow the runtime shadow toggle; AW and Free
meshes still do.

Rebuild all TOF impostors with a Godot window available for rendering:

```sh
: "${GODOT_BIN:=godot}"
"$GODOT_BIN" --rendering-method mobile --path "$PWD" \
    --script res://tools/bake_tof_impostors.gd
```

To rebuild one resource while checking the pipeline, add:

```sh
-- --resource=res://resources/terrain/trees_3_overtile.tres
```

The baker compares a neutral ground receiver with and without each mesh's cast
shadow, composites that shadow beneath the object capture, then fails on empty
or clipped combined captures instead of saving incomplete assets. Do not run it
with `--headless`: Godot uses a dummy renderer there and cannot capture viewport
textures.

## Making changes

Follow existing GDScript style and keep changes within the owning layer. When
adding or moving a map template, update `res://scenes/map/templates.gd` and
search for stale resource paths. Prefer shared material and tile behavior over
per-resource overrides.

Before submitting a non-trivial change, run:

```sh
git diff --check
./tools/run_gut.sh
: "${GODOT_BIN:=godot}"
HOME=/private/tmp "$GODOT_BIN" --headless --path "$PWD" --quit
```

The normal headless load can print shutdown leak warnings. A non-zero exit
code, parser error, stale resource path, or new script error is a failure.
