# BoardView Phase 3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Introduce a concrete `BoardView` boundary so `BoardController` talks to a view adapter instead of the full `Board` scene.

**Architecture:** This phase starts with a thin scene-backed adapter. `Board` remains the composition root and concrete presentation host, while `BoardView` exposes the presentation callbacks the controller needs. Later Phase 3 work can move marker drawing, UI updates, camera, audio, and animation behavior behind this adapter incrementally.

**Tech Stack:** Godot 4.7, GDScript, GUT 9.7.

---

## File Structure

- Create `scenes/board/board_view.gd` with `class_name BoardView`.
- Modify `scenes/board/board_controller.gd` so its `view` dependency is typed as `BoardView`.
- Modify `scenes/board/board.gd` so it constructs `BoardView.new(self)` and passes it to `BoardController`.
- Modify `tests/unit/board/test_board_controller.gd` so fake views extend `BoardView`.
- Create `tests/unit/board/test_board_view.gd` for low-dependency adapter tests.

## Task 1: Introduce BoardView Adapter Boundary

**Files:**
- Create: `scenes/board/board_view.gd`
- Create: `tests/unit/board/test_board_view.gd`
- Modify: `tests/unit/board/test_board_controller.gd`
- Modify: `scenes/board/board_controller.gd`
- Modify: `scenes/board/board.gd`

- [x] **Step 1: Write failing BoardView adapter tests**

Add tests that prove `BoardView` delegates controller-facing presentation callbacks to its board host.

- [x] **Step 2: Run GUT to verify it fails**

Run:

```bash
./tools/run_gut.sh
```

Expected: FAIL because `BoardView` does not exist yet.

- [x] **Step 3: Add BoardView adapter**

Create `BoardView` with `unselect_tile()`, `cancel_ability()`, `show_contextual_select()`, `hover_tile()`, and `play_tile_selected_feedback()` delegating to the board host.

- [x] **Step 4: Type BoardController view dependency**

Update `BoardController.view` and `attach_view()` to use `BoardView`, and update controller tests so fake views extend `BoardView`.

- [x] **Step 5: Wire Board through BoardView**

Add `var board_view: BoardView` to `Board`, initialize it with `BoardView.new(self)`, and pass that adapter to `BoardController`.

- [x] **Step 6: Run GUT**

Run:

```bash
./tools/run_gut.sh
```

Expected: PASS.

## Task 2: Add Null View Behavior

**Files:**
- Modify: `scenes/board/board_view.gd`
- Modify: `scenes/board/board_controller.gd`
- Modify: `tests/unit/board/test_board_controller.gd`

- [x] **Step 1: Write failing null-view controller test**

Add a controller test that presses a selectable tile without attaching a scene-backed view.

- [x] **Step 2: Run GUT to verify it fails**

Run:

```bash
./tools/run_gut.sh
```

Expected: FAIL because `BoardController.press_tile()` requires a non-null view.

- [x] **Step 3: Make hostless BoardView a no-op view**

Update `BoardView` so presentation callbacks return early when no board host is attached.

- [x] **Step 4: Default BoardController to a null BoardView**

Initialize `BoardController.view` with `BoardView.new()` and remove the non-null view assertions.

- [x] **Step 5: Run GUT**

Run:

```bash
./tools/run_gut.sh
```

Expected: PASS.

## Task 3: Split Cancel And Unselect View Cleanup

**Files:**
- Modify: `scenes/board/board_controller.gd`
- Modify: `scenes/board/board_view.gd`
- Modify: `scenes/board/board.gd`
- Modify: `tests/unit/board/test_board_controller.gd`
- Modify: `tests/unit/board/test_board_view.gd`

- [x] **Step 1: Write failing controller state tests**

Add tests proving `BoardController.cancel_interaction()` clears active ability targeting state and selected tile state directly instead of relying on the scene-backed board.

- [x] **Step 2: Run GUT to verify it fails**

Run:

```bash
./tools/run_gut.sh
```

Expected: FAIL because the controller still leaves cancellation state clearing to the view/board compatibility methods.

- [x] **Step 3: Split controller state from view cleanup**

Update `BoardController.cancel_interaction()` to clear controller state before asking the view to update visuals.

- [x] **Step 4: Add view-only cleanup methods on Board**

Add `Board.clear_selection_view()` and `Board.clear_ability_view()`. Keep `Board.unselect_tile()` and `Board.cancel_ability()` as compatibility methods that coordinate controller state plus view cleanup.

- [x] **Step 5: Run GUT**

Run:

```bash
./tools/run_gut.sh
```

Expected: PASS.

## Task 4: Move Contextual Selection Presentation Into BoardView

**Files:**
- Modify: `scenes/board/board_view.gd`
- Modify: `scenes/board/board.gd`
- Modify: `tests/unit/board/test_board_view.gd`

- [x] **Step 1: Write failing BoardView contextual selection test**

Update the BoardView test so `show_contextual_select()` must call marker placement, marker reset, optional unit marker drawing, and radial population directly on its board host.

- [x] **Step 2: Run GUT to verify it fails**

Run:

```bash
./tools/run_gut.sh
```

Expected: FAIL because `BoardView.show_contextual_select()` still delegates to `Board.show_contextual_select()`.

- [x] **Step 3: Move contextual selection sequence into BoardView**

Update `BoardView.show_contextual_select()` to perform the view sequence. Change `Board.show_contextual_select()` into a compatibility wrapper that delegates to `board_view`.

- [x] **Step 4: Run GUT**

Run:

```bash
./tools/run_gut.sh
```

Expected: PASS.

## Task 5: Final Verification

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
