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
