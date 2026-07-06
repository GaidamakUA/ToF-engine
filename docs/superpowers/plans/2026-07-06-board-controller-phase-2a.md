# BoardController Phase 2a Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Introduce `BoardController` as the owner of board interaction state while preserving current board behavior.

**Architecture:** This phase is a compatibility slice. `BoardController` stores selection and active ability targeting state, while `Board` keeps the existing view methods and rule-routing code. Compatibility properties on `Board` keep existing callers working until later phase 2 tasks move tile press interpretation into the controller.

**Tech Stack:** Godot 4.7, GDScript, GUT 9.7.

---

## File Structure

- Create `scenes/board/board_controller.gd` with `class_name BoardController`.
- Create `tests/unit/board/test_board_controller.gd` for low-dependency controller state tests.
- Modify `scenes/board/board.gd` to construct `BoardController` and expose compatibility accessors for `selected_tile`, `active_ability`, and `active_ability_origin_tile`.

## Task 1: Add BoardController State Boundary

**Files:**
- Create: `tests/unit/board/test_board_controller.gd`
- Create: `scenes/board/board_controller.gd`

- [x] **Step 1: Write failing controller state tests**

Add tests that construct `BoardController`, assign a selected tile and active ability, then verify `clear_selection()` and `cancel_ability()` clear only the expected interaction state.

- [x] **Step 2: Run test to verify it fails**

Run:

```bash
./tools/run_gut.sh
```

Expected: FAIL because `BoardController` is not declared.

- [x] **Step 3: Add minimal BoardController**

Create `BoardController` with `model`, `selected_tile`, `active_ability`, `active_ability_origin_tile`, `select_tile()`, `start_ability_targeting()`, `cancel_ability()`, and `clear_selection()`.

- [x] **Step 4: Run test to verify it passes**

Run:

```bash
./tools/run_gut.sh
```

Expected: PASS.

## Task 2: Wire Board Interaction State Through BoardController

**Files:**
- Modify: `scenes/board/board.gd`
- Modify: `tests/unit/board/test_board_controller.gd`

- [x] **Step 1: Write failing board wiring test**

Add a test that constructs `Board`, verifies it has a controller, assigns the compatibility `selected_tile`, `active_ability`, and `active_ability_origin_tile` properties, and verifies the controller receives the same objects.

- [x] **Step 2: Run test to verify it fails**

Run:

```bash
./tools/run_gut.sh
```

Expected: FAIL because `Board` does not expose interaction state through `BoardController`.

- [x] **Step 3: Wire Board to BoardController**

Add `var controller: BoardController` to `Board`, initialize it in `_init()` after `board_model` is created, and replace direct stored interaction fields with compatibility properties backed by the controller.

- [x] **Step 4: Run GUT to verify board wiring**

Run:

```bash
./tools/run_gut.sh
```

Expected: PASS.

## Task 3: Final Verification

**Files:**
- No file changes.

- [x] **Step 1: Run whitespace check**

Run:

```bash
git diff --check
```

Expected: no output.

- [x] **Step 2: Run GUT suite**

Run:

```bash
./tools/run_gut.sh
```

Expected: all tests pass.

- [x] **Step 3: Run headless project load**

Run:

```bash
: "${GODOT_BIN:=godot}"
HOME=/private/tmp "$GODOT_BIN" --headless --path "$PWD" --quit
```

Expected: exit `0`, with only existing warnings/shutdown leak output.

## Task 4: Move Tile Press Interpretation Into BoardController

**Files:**
- Modify: `scenes/board/board_controller.gd`
- Modify: `scenes/board/board.gd`
- Modify: `tests/unit/board/test_board_controller.gd`

- [x] **Step 1: Write failing controller routing tests**

Add tests with a fake model and fake view host for selection, same-tile ability opening, movement routing, interaction routing, and invalid ability-target cancellation.

- [x] **Step 2: Run test to verify it fails**

Run:

```bash
./tools/run_gut.sh
```

Expected: FAIL because `BoardController.attach_view()` and `BoardController.press_tile()` are missing.

- [x] **Step 3: Add controller tile-press routing**

Add `BoardController.attach_view()` and `BoardController.press_tile()`. Route gameplay operations through `BoardModel` and keep view feedback on the scene-backed view host.

- [x] **Step 4: Delegate Board.select_tile() to BoardController**

Keep camera and hover-menu guards in `Board`, then forward accepted tile presses to `controller.press_tile()`. Add small model bridge methods for tile lookup, current-player selectability, ability markers, AI checks, movement, and interaction, with click feedback staying on `Board` as view behavior.

- [x] **Step 5: Run GUT**

Run:

```bash
./tools/run_gut.sh
```

Expected: PASS.

## Task 6: Route Controller Gameplay Calls Through BoardModel

**Files:**
- Modify: `scenes/board/board_controller.gd`
- Modify: `scenes/board/board_model.gd`
- Modify: `tests/unit/board/test_board_controller.gd`

- [x] **Step 1: Split controller tests into fake model and fake view**

Update controller tests so tile lookup, selectability, movement, interaction, and ability execution are verified on a fake `BoardModel`, while unselect/cancel/contextual-select/hover/click feedback are verified on a fake view host.

- [x] **Step 2: Run test to verify it fails**

Run:

```bash
./tools/run_gut.sh
```

Expected: FAIL because the controller still has one board host instead of split model/view responsibilities.

- [x] **Step 3: Update BoardController dependencies**

Replace the controller `board` host with `view`, add `attach_view()`, route gameplay checks and operations through `BoardModel`, and keep only presentation callbacks on `view`.

- [x] **Step 4: Add BoardModel bridge operations**

Add explicit `BoardModel` methods for the controller operations. During this migration slice they delegate to the existing scene-backed board host.

- [x] **Step 5: Run GUT**

Run:

```bash
./tools/run_gut.sh
```

Expected: PASS.

## Task 5: Move Cancel Interpretation Into BoardController

**Files:**
- Modify: `scenes/board/board_controller.gd`
- Modify: `scenes/board/board.gd`
- Modify: `tests/unit/board/test_board_controller.gd`

- [x] **Step 1: Write failing cancel routing tests**

Add tests that verify cancel routes to ability cancellation while targeting and to tile unselection otherwise.

- [x] **Step 2: Run test to verify it fails**

Run:

```bash
./tools/run_gut.sh
```

Expected: FAIL because `BoardController.cancel()` is missing.

- [x] **Step 3: Add controller cancel routing**

Add `BoardController.cancel()` and delegate `Board.unselect_action()` to it.

- [x] **Step 4: Route ability targeting activation through BoardController**

Update unit and production ability activation to call `controller.start_ability_targeting()` instead of assigning active ability fields directly.

- [x] **Step 5: Run GUT**

Run:

```bash
./tools/run_gut.sh
```

Expected: PASS.
