# Board MVC Phase 5 - Headless Validation Path

## Goal

Add a small, repeatable validation path that exercises `BoardModel` commands without instancing the Board UI scene.

## Tasks

1. Add a bundled headless map fixture for a compact tactical scenario.
2. Add a test harness that loads the fixture, creates `BoardModel`, attaches a no-UI host, and exposes fixture tiles.
3. Add GUT coverage for model setup, movement, turn switching, emitted gameplay events, AI move execution, capture action execution, AP reserve, ability command dispatch, and fixture restore.
4. Run focused GUT validation, full GUT validation, diff checks, personal-path scan, and Godot headless load.

## Notes

- Keep this as validation infrastructure, not another Board orchestration refactor.
- The harness should use the same `MapTile`, `BaseUnit`, `BaseBuilding`, `BoardModel`, actions, and event objects as production code.
- Avoid selection marker/view methods so failures catch accidental UI coupling.
