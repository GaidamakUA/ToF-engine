# Board AI Model Commands Phase 4 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move AI action execution away from `Board.select_tile()` and onto explicit `BoardModel` commands.

**Architecture:** This is a compatibility slice. `BoardModel` exposes AI-facing commands that delegate to existing board rule methods, while `Board` keeps scene-backed animation, timers, and effects. AI actions receive `BoardModel` and execute commands directly instead of simulating human selection clicks.

**Tech Stack:** Godot 4.7, GDScript, GUT 9.7.

---

## File Structure

- Modify `scenes/board/board_model.gd` with explicit AI command methods.
- Modify `scenes/board/board.gd` with source-explicit interaction and ability helpers.
- Modify `scenes/board/logic/ai/ai.gd` to pass `board.board_model` into actions.
- Modify `scenes/board/logic/ai/actions/*.gd` so action `perform()` methods accept `BoardModel`.
- Add `tests/unit/board/ai/test_ai_actions.gd` for deterministic action execution tests.

## Task 1: Route Move And Reserve Actions Through BoardModel

**Files:**
- Modify: `scenes/board/board_model.gd`
- Modify: `scenes/board/logic/ai/ai.gd`
- Modify: `scenes/board/logic/ai/actions/abstract_action.gd`
- Modify: `scenes/board/logic/ai/actions/move_action.gd`
- Modify: `scenes/board/logic/ai/actions/reserve_ap_action.gd`
- Create: `tests/unit/board/ai/test_ai_actions.gd`

- [x] **Step 1: Write failing AI action tests**

Add tests that create a `BoardModel` with a fake board host, perform `MoveAction` and `ReserveApAction`, and assert no selection methods are called.

- [x] **Step 2: Run GUT to verify it fails**

Run:

```bash
./tools/run_gut.sh
```

Expected: FAIL because actions still require `Board` and call `select_tile()`.

- [x] **Step 3: Add model command methods**

Use `BoardModel.move_unit_along_path(source_tile, destination_tile, move_cost, movement_path)` for action execution and add `BoardModel.reserve_ap(amount)`.

- [x] **Step 4: Update action execution signature**

Change `AbstractAction.perform()` and the move/reserve action implementations to accept `BoardModel`. Update `Ai._ai_tick()` to call `selected_action.perform(self.board.board_model)`.

- [x] **Step 5: Run GUT**

Run:

```bash
./tools/run_gut.sh
```

Expected: PASS.

## Task 2: Route Attack And Capture Actions Through BoardModel

**Files:**
- Modify: `scenes/board/board_model.gd`
- Modify: `scenes/board/board.gd`
- Modify: `scenes/board/logic/ai/actions/attack_action.gd`
- Modify: `scenes/board/logic/ai/actions/capture_action.gd`
- Modify: `tests/unit/board/ai/test_ai_actions.gd`

- [x] **Step 1: Write failing attack and capture tests**

Add tests proving `AttackAction.perform(model)` and `CaptureAction.perform(model)` call source-explicit model interaction commands and never call `select_tile()`.

- [x] **Step 2: Run GUT to verify it fails**

Run:

```bash
./tools/run_gut.sh
```

Expected: FAIL because attack and capture actions still simulate tile selection.

- [x] **Step 3: Add source-explicit board interaction helper**

Add `Board.handle_interaction_from_tile(source_tile, target_tile)` by extracting the rule body from `Board.handle_interaction(tile)`.

- [x] **Step 4: Add model interaction command**

Add `BoardModel.interact_unit(source_tile, interaction_tile, target_tile)` so attack/capture happens through `handle_interaction_from_tile()`. When an action needs to move first, the action should call `move_unit_along_path()` with its AI-computed movement path before interacting.

- [x] **Step 5: Update attack and capture actions**

Update `AttackAction.perform(model)` and `CaptureAction.perform(model)` to call `model.interact_unit(self.unit, self.interaction, self.target)`.

- [x] **Step 6: Run GUT**

Run:

```bash
./tools/run_gut.sh
```

Expected: PASS.

## Task 3: Route Ability Actions Through BoardModel

**Files:**
- Modify: `scenes/board/board_model.gd`
- Modify: `scenes/board/board.gd`
- Modify: `scenes/board/logic/ai/actions/use_ability_action.gd`
- Modify: `tests/unit/board/ai/test_ai_actions.gd`

- [x] **Step 1: Write failing ability action test**

Add a test proving `UseAbilityAction.perform(model)` calls a source-explicit ability model command and never sets `selected_tile` or calls `select_tile()`.

- [x] **Step 2: Run GUT to verify it fails**

Run:

```bash
./tools/run_gut.sh
```

Expected: FAIL because ability actions still manipulate board selection state.

- [x] **Step 3: Add source-explicit board ability helper**

Add `Board.execute_ability_from_tile(origin_tile, ability, target_tile)` by extracting the execution body from `Board.execute_active_ability(target_tile)`.

- [x] **Step 4: Add model ability command**

Add `BoardModel.use_ability(origin_tile, ability, target_tile)` delegating to `Board.execute_ability_from_tile()`.

- [x] **Step 5: Update ability action**

Update `UseAbilityAction.perform(model)` to call `model.use_ability(self.origin_tile, self.ability, self.target)`.

- [x] **Step 6: Run GUT**

Run:

```bash
./tools/run_gut.sh
```

Expected: PASS.

## Task 4: Final Verification

**Files:**
- No file changes.

- [x] **Step 1: Scan for AI selection execution**

Run:

```bash
rg -n "select_tile|selected_tile|unselect_tile" scenes/board/logic/ai/actions scenes/board/logic/ai/ai.gd
```

Expected: no action execution calls to selection APIs.

- [x] **Step 2: Run whitespace check**

Run:

```bash
git diff --check
```

Expected: no output.

- [x] **Step 3: Run GUT suite**

Run:

```bash
./tools/run_gut.sh
```

Expected: all tests pass.

- [x] **Step 4: Run headless project load**

Run:

```bash
: "${GODOT_BIN:=godot}"
HOME=/private/tmp "$GODOT_BIN" --headless --path "$PWD" --quit
```

Expected: exit `0`, with only existing warnings/shutdown leak output.
