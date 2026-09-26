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

The board is split into three cooperating parts:

- `Board` is the Godot scene host. It owns scene nodes, presentation, input,
  audio, animation, and compatibility entry points.
- `BoardModel` owns gameplay collaborators and exposes commands used by the
  controller, AI, multiplayer, and headless tests.
- `BoardController` owns interaction state such as tile selection and ability
  targeting. It emits requests for visual updates rather than manipulating UI
  nodes directly.

The map follows a similar boundary. `MapModel` owns the 40×40 logical grid and
serialized data, `MapBuilder` places or removes runtime objects, and
`MapLoader` handles current and legacy map data. Template names are registered
centrally in `res://scenes/map/templates.gd`.

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
- `GroundTileResource` defines reusable ground meshes, movement properties,
  offsets, shadows, reflections, and damage-stage template names.

Do not duplicate these resources for each placed object, and do not put
runtime values into them. Damaged and destroyed city/decor scenes remain
`PackedScene` templates.

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
