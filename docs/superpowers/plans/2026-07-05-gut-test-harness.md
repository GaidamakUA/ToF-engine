# GUT Test Harness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a headless GUT test harness and baseline tests for existing `State` behavior before the board MVC extraction begins.

**Architecture:** This plan only adds test tooling and tests for already-isolated logic. Product gameplay code should not change in this phase. The first stable boundary is `State`, so tests exercise `State` directly and avoid the current `Board` scene.

**Tech Stack:** Godot 4.7, GDScript, GUT 9.x for Godot 4, shell runner for local headless execution.

---

## File Structure

- Create `addons/gut/` by installing the GUT Godot 4.7 addon.
- Create `tools/run_gut.sh` as the project-local headless GUT runner.
- Create `tests/unit/test_gut_harness.gd` for a minimal harness smoke test.
- Create `tests/unit/board/logic/test_state.gd` for `State` behavior tests.
- Modify no product source files in this phase.

## Task 1: Install GUT Addon

**Files:**
- Create: `addons/gut/`

- [ ] **Step 1: Verify GUT is not already installed**

Run:

```bash
test ! -e addons/gut
```

Expected: command exits with status `0`.

- [ ] **Step 2: Download GUT for Godot 4.7**

Run:

```bash
curl -L https://github.com/bitwes/Gut/archive/refs/heads/godot_4_7.zip -o /tmp/gut-godot-4-7.zip
```

Expected: command exits with status `0` and creates `/tmp/gut-godot-4-7.zip`.

- [ ] **Step 3: Unpack GUT**

Run:

```bash
unzip -q /tmp/gut-godot-4-7.zip -d /tmp
```

Expected: command exits with status `0` and creates `/tmp/Gut-godot_4_7`.

- [ ] **Step 4: Copy the addon into the project**

Run:

```bash
mkdir -p addons
cp -R /tmp/Gut-godot_4_7/addons/gut addons/gut
```

Expected: command exits with status `0` and `addons/gut/gut_cmdln.gd` exists.

- [ ] **Step 5: Confirm the command-line runner exists**

Run:

```bash
test -f addons/gut/gut_cmdln.gd
```

Expected: command exits with status `0`.

- [ ] **Step 6: Commit**

Run:

```bash
git add addons/gut
git commit -m "test: add GUT addon"
```

Expected: commit succeeds.

## Task 2: Add Headless GUT Runner

**Files:**
- Create: `tools/run_gut.sh`

- [ ] **Step 1: Create the runner script**

Create `tools/run_gut.sh`:

```sh
#!/usr/bin/env sh
set -eu

PROJECT_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

if [ -z "${GODOT_BIN:-}" ]; then
    GODOT_BIN="$HOME/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot"
fi

HOME=/private/tmp "$GODOT_BIN" \
    --headless \
    -d \
    --path "$PROJECT_ROOT" \
    -s addons/gut/gut_cmdln.gd \
    -gdir=res://tests/unit \
    -ginclude_subdirs \
    -gexit
```

- [ ] **Step 2: Make the runner executable**

Run:

```bash
chmod +x tools/run_gut.sh
```

Expected: command exits with status `0`.

- [ ] **Step 3: Confirm the runner is executable**

Run:

```bash
test -x tools/run_gut.sh
```

Expected: command exits with status `0`.

- [ ] **Step 4: Commit**

Run:

```bash
git add tools/run_gut.sh
git commit -m "test: add headless GUT runner"
```

Expected: commit succeeds.

## Task 3: Add GUT Harness Smoke Test

**Files:**
- Create: `tests/unit/test_gut_harness.gd`

- [ ] **Step 1: Write the smoke test**

Create `tests/unit/test_gut_harness.gd`:

```gdscript
extends GutTest


func test_gut_harness_runs() -> void:
    assert_true(true)
```

- [ ] **Step 2: Run the smoke test**

Run:

```bash
./tools/run_gut.sh
```

Expected: PASS with `test_gut_harness_runs`.

- [ ] **Step 3: Commit**

Run:

```bash
git add tests/unit/test_gut_harness.gd tools/run_gut.sh
git commit -m "test: add GUT harness smoke test"
```

Expected: commit succeeds.

## Task 4: Add State Unit Tests

**Files:**
- Create: `tests/unit/board/logic/test_state.gd`

- [ ] **Step 1: Write `State` tests**

Create `tests/unit/board/logic/test_state.gd`:

```gdscript
extends GutTest


func _make_state() -> State:
    var state := State.new()
    state.add_player(State.PLAYER_HUMAN, "blue", true, 0)
    state.add_player(State.PLAYER_AI, "red", true, 1)
    state.add_player(State.PLAYER_HUMAN, "green", true, 0)
    return state


func test_add_player_ap_clamps_to_upper_limit() -> void:
    var state := _make_state()

    state.add_player_ap(0, 1000)

    assert_eq(state.get_player_ap(0), 999)


func test_add_player_ap_clamps_to_zero() -> void:
    var state := _make_state()

    state.add_player_ap(0, -5)

    assert_eq(state.get_player_ap(0), 0)


func test_use_player_ap_clamps_to_zero_and_marks_player_moved() -> void:
    var state := _make_state()
    state.add_player_ap(0, 2)

    state.use_player_ap(0, 5)

    assert_eq(state.get_player_ap(0), 0)
    assert_true(state.has_player_moved)


func test_switch_to_next_player_advances_current_player() -> void:
    var state := _make_state()

    state.switch_to_next_player()

    assert_eq(state.current_player, 1)
    assert_eq(state.turn, 1)
    assert_false(state.has_player_moved)


func test_switch_to_next_player_wraps_and_increments_turn() -> void:
    var state := _make_state()
    state.current_player = 2

    state.switch_to_next_player()

    assert_eq(state.current_player, 0)
    assert_eq(state.turn, 2)


func test_switch_to_next_player_skips_dead_players() -> void:
    var state := _make_state()
    state.eliminate_player("red")

    state.switch_to_next_player()

    assert_eq(state.get_current_side(), "green")


func test_get_player_id_and_side_by_side() -> void:
    var state := _make_state()

    assert_eq(state.get_player_id_by_side("red"), 1)
    assert_eq(state.get_player_side_by_id(2), "green")


func test_get_player_team_uses_explicit_team_or_player_index() -> void:
    var state := State.new()
    state.add_player(State.PLAYER_HUMAN, "blue")
    state.add_player(State.PLAYER_AI, "red", true, 5)

    assert_eq(state.get_player_team("blue"), 0)
    assert_eq(state.get_player_team("red"), 5)
```

- [ ] **Step 2: Run the `State` tests**

Run:

```bash
./tools/run_gut.sh
```

Expected: PASS with the harness smoke test and all `State` tests.

- [ ] **Step 3: Run the project smoke load**

Run:

```bash
HOME=/private/tmp "$HOME/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot" --headless --path /Users/Personal/workspace/godot/ToF-engine --quit
```

Expected: exit code `0`. Shutdown leak warnings are acceptable. Parser errors, stale resource paths, or new script errors are failures.

- [ ] **Step 4: Commit**

Run:

```bash
git add tests/unit/board/logic/test_state.gd
git commit -m "test: cover board state behavior"
```

Expected: commit succeeds.

## Task 5: Final Verification

**Files:**
- Verify: `addons/gut/`
- Verify: `tools/run_gut.sh`
- Verify: `tests/unit/test_gut_harness.gd`
- Verify: `tests/unit/board/logic/test_state.gd`

- [ ] **Step 1: Check formatting whitespace**

Run:

```bash
git diff --check
```

Expected: no output and exit code `0`.

- [ ] **Step 2: Run GUT**

Run:

```bash
./tools/run_gut.sh
```

Expected: all tests pass.

- [ ] **Step 3: Run Godot headless project load**

Run:

```bash
HOME=/private/tmp "$HOME/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot" --headless --path /Users/Personal/workspace/godot/ToF-engine --quit
```

Expected: exit code `0`. Shutdown leak warnings are acceptable. Parser errors, stale resource paths, or new script errors are failures.

- [ ] **Step 4: Check working tree**

Run:

```bash
git status --short
```

Expected: no output.
