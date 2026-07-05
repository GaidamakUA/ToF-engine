# BoardModel Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Introduce `BoardModel` as the first gameplay model boundary while preserving current board behavior.

**Architecture:** `BoardModel` owns the existing gameplay collaborators and state-facing convenience API, but still accepts the current `Board` scene as a runtime host for scene-dependent rule helpers. `Board` remains the composition root and concrete view/controller host during this phase, with compatibility aliases so existing callers keep working.

**Tech Stack:** Godot 4.7, GDScript, GUT 9.7.

---

## Execution Note

During implementation, `BoardModel` was adjusted to avoid creating board-dependent collaborators in a hostless model. The verified shape is:

- `BoardModel.new()` owns headless collaborators: `State`, `Events`, `Scripting`, and `RadialAbilities`.
- `BoardModel.attach_board(board)` creates board-dependent collaborators: `Abilities`, `Observers`, `Ai`, and `Collateral`.
- `Board` constructs `BoardModel`, aliases state/events/scripting first, then calls `attach_board(self)` so `Observers` can register through `board.events`.

## File Structure

- Create `scenes/board/board_model.gd` with `class_name BoardModel`.
- Create `tests/unit/board/test_board_model.gd` for low-dependency model boundary tests.
- Modify `scenes/board/board.gd` so it constructs `BoardModel` and exposes existing fields through the model.
- Do not move `selected_tile`, `active_ability`, markers, input handling, camera, UI, animation, or audio in this phase.

## Task 1: Add BoardModel Constructor Boundary

**Files:**
- Create: `tests/unit/board/test_board_model.gd`
- Create: `scenes/board/board_model.gd`

- [ ] **Step 1: Write the failing constructor test**

Create `tests/unit/board/test_board_model.gd`:

```gdscript
extends GutTest


func test_new_model_owns_gameplay_collaborators() -> void:
    var model := BoardModel.new()

    assert_not_null(model.state)
    assert_not_null(model.events)
    assert_not_null(model.scripting)
    assert_not_null(model.abilities)
    assert_not_null(model.observers)
    assert_not_null(model.ai)
    assert_not_null(model.collateral)
    assert_not_null(model.radial_abilities)
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
./tools/run_gut.sh
```

Expected: FAIL because `BoardModel` is not declared.

- [ ] **Step 3: Add minimal BoardModel**

Create `scenes/board/board_model.gd`:

```gdscript
class_name BoardModel


var board: Board = null
var state: State = State.new()
var radial_abilities: RadialAbilities = RadialAbilities.new()
var abilities: Abilities
var events: Events = Events.new()
var observers: Observers
var scripting: Scripting = Scripting.new()
var ai: Ai
var collateral: Collateral


func _init(board_host: Board = null) -> void:
    self.board = board_host
    self.abilities = Abilities.new(board_host)
    self.observers = Observers.new(board_host)
    self.ai = Ai.new(board_host)
    self.collateral = Collateral.new(board_host)
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
./tools/run_gut.sh
```

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add scenes/board/board_model.gd tests/unit/board/test_board_model.gd
git commit -m "feat: add board model boundary"
```

Expected: commit succeeds.

## Task 2: Add State-Facing BoardModel API

**Files:**
- Modify: `tests/unit/board/test_board_model.gd`
- Modify: `scenes/board/board_model.gd`

- [ ] **Step 1: Write failing state API tests**

Append to `tests/unit/board/test_board_model.gd`:

```gdscript

func _make_model_with_players() -> BoardModel:
    var model := BoardModel.new()
    model.add_player({
        "type": State.PLAYER_HUMAN,
        "side": "blue",
        "alive": true,
        "team": 0,
        "ap": 3,
    })
    model.add_player({
        "type": State.PLAYER_AI,
        "side": "red",
        "alive": true,
        "team": 1,
        "ap": 2,
    })
    return model


func test_add_player_initializes_state_ap_and_team() -> void:
    var model := _make_model_with_players()

    assert_eq(model.get_current_side(), "blue")
    assert_eq(model.get_current_ap(), 3)
    assert_eq(model.get_player_team("blue"), 0)
    assert_eq(model.get_player_team("red"), 1)


func test_use_and_add_current_player_ap_delegate_to_state() -> void:
    var model := _make_model_with_players()

    model.use_current_player_ap(5)
    assert_eq(model.get_current_ap(), 0)
    assert_true(model.state.has_player_moved)

    model.add_current_player_ap(4)
    assert_eq(model.get_current_ap(), 4)


func test_end_turn_switches_to_next_player() -> void:
    var model := _make_model_with_players()

    model.end_turn()

    assert_eq(model.state.current_player, 1)
    assert_eq(model.get_current_side(), "red")
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
./tools/run_gut.sh
```

Expected: FAIL because `BoardModel.add_player` and related methods are missing.

- [ ] **Step 3: Add minimal state-facing API**

Add these methods to `scenes/board/board_model.gd`:

```gdscript
func add_player(data: Dictionary[String, Variant]) -> void:
    self.state.add_player(String(data["type"]), String(data["side"]), bool(data["alive"]), data["team"])
    var player_id: int = self.state.players.size() - 1
    if data.has("ap"):
        self.state.add_player_ap(player_id, int(data["ap"]))
    self.state.set_player_team(String(data["side"]), self.state.get_player_team(String(data["side"])))


func get_current_player() -> Dictionary:
    return self.state.get_current_player()


func get_current_side() -> String:
    return self.state.get_current_side()


func get_current_team() -> int:
    return self.state.get_current_team()


func get_current_ap() -> int:
    return self.state.get_current_ap()


func get_player_team(side: String) -> int:
    return self.state.get_player_team(side)


func add_current_player_ap(value: int) -> void:
    self.state.add_current_player_ap(value)


func use_current_player_ap(value: int) -> void:
    self.state.use_current_player_ap(value)


func can_current_player_afford(amount: int) -> bool:
    return self.state.can_current_player_afford(amount)


func end_turn() -> void:
    self.state.switch_to_next_player()
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
./tools/run_gut.sh
```

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add scenes/board/board_model.gd tests/unit/board/test_board_model.gd
git commit -m "feat: expose board model state api"
```

Expected: commit succeeds.

## Task 3: Wire Board Through BoardModel

**Files:**
- Modify: `scenes/board/board.gd`
- Modify: `tests/unit/board/test_board_model.gd`

- [ ] **Step 1: Write failing board-host test**

Append to `tests/unit/board/test_board_model.gd`:

```gdscript

func test_model_collaborators_receive_board_host() -> void:
    var board := Board.new()
    var model := BoardModel.new(board)

    assert_same(model.board, board)
    assert_same(model.abilities.board, board)
    assert_same(model.observers.board, board)
    assert_same(model.ai.board, board)
    assert_same(model.collateral.board, board)
```

- [ ] **Step 2: Run test to verify it passes before board wiring**

Run:

```bash
./tools/run_gut.sh
```

Expected: PASS. This proves the model can host the current board before `Board` delegates to it.

- [ ] **Step 3: Modify Board fields to delegate through BoardModel**

In `scenes/board/board.gd`, replace the current gameplay collaborator fields:

```gdscript
var state: State = State.new()
var radial_abilities: RadialAbilities = RadialAbilities.new()
var abilities: Abilities = Abilities.new(self)
var events: Events = Events.new()
var observers: Observers = Observers.new(self)
var scripting: Scripting = Scripting.new()
var ai: Ai = Ai.new(self)
var collateral: Collateral = Collateral.new(self)
```

with:

```gdscript
var model: BoardModel
var state: State
var radial_abilities: RadialAbilities
var abilities: Abilities
var events: Events
var observers: Observers
var scripting: Scripting
var ai: Ai
var collateral: Collateral
```

Add this method before `_ready()`:

```gdscript
func _init() -> void:
    self.model = BoardModel.new(self)
    self.state = self.model.state
    self.radial_abilities = self.model.radial_abilities
    self.abilities = self.model.abilities
    self.events = self.model.events
    self.observers = self.model.observers
    self.scripting = self.model.scripting
    self.ai = self.model.ai
    self.collateral = self.model.collateral
```

- [ ] **Step 4: Run GUT to verify board wiring still loads**

Run:

```bash
./tools/run_gut.sh
```

Expected: PASS.

- [ ] **Step 5: Run headless project load**

Run:

```bash
: "${GODOT_BIN:=godot}"
HOME=/private/tmp "$GODOT_BIN" --headless --path "$PWD" --quit
```

Expected: exit `0`, with only existing warnings/shutdown leak output.

- [ ] **Step 6: Commit**

Run:

```bash
git add scenes/board/board.gd tests/unit/board/test_board_model.gd
git commit -m "refactor: wire board through board model"
```

Expected: commit succeeds.

## Task 4: Final Verification

**Files:**
- No file changes.

- [ ] **Step 1: Run whitespace check**

Run:

```bash
git diff --check
```

Expected: no output.

- [ ] **Step 2: Run GUT suite**

Run:

```bash
./tools/run_gut.sh
```

Expected: all tests pass.

- [ ] **Step 3: Run headless project load**

Run:

```bash
: "${GODOT_BIN:=godot}"
HOME=/private/tmp "$GODOT_BIN" --headless --path "$PWD" --quit
```

Expected: exit `0`, with only existing warnings/shutdown leak output.
