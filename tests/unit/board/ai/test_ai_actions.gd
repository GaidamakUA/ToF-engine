extends GutTest


class RecordingBoardModel:
	extends BoardModel

	var moves: Array[Array] = []
	var attacks: Array[Array] = []
	var captures: Array[Array] = []
	var ability_uses: Array[Array] = []

	func move_unit(source: Vector2i, destination: Vector2i) -> bool:
		self.moves.append([source, destination])
		return true

	func attack_unit(source: Vector2i, target: Vector2i) -> bool:
		self.attacks.append([source, target])
		return true

	func capture_building(source: Vector2i, target: Vector2i) -> bool:
		self.captures.append([source, target])
		return true

	func use_ability(origin: Vector2i, ability_key: String, target: Vector2i) -> bool:
		self.ability_uses.append([origin, ability_key, target])
		return true


class PresentationGate:
	extends RefCounted

	signal opened

	var wait_count: int = 0

	func wait() -> void:
		self.wait_count += 1
		await self.opened


func test_move_action_calls_position_based_model_command() -> void:
	var model := RecordingBoardModel.new()
	var source := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)
	var action := MoveAction.new(source, target, ["1_0", "0_0"])

	action.perform(model)

	assert_eq(model.moves, [[Vector2i(0, 0), Vector2i(1, 0)]])


func test_attack_action_moves_then_attacks_from_interaction_position() -> void:
	var model := RecordingBoardModel.new()
	var source := MapTile.new(0, 0)
	var interaction := MapTile.new(1, 0)
	var target := MapTile.new(2, 0)
	var action := AttackAction.new(source, interaction, target, ["1_0", "0_0"])

	action.perform(model)

	assert_eq(model.moves, [[Vector2i(0, 0), Vector2i(1, 0)]])
	assert_eq(model.attacks, [[Vector2i(1, 0), Vector2i(2, 0)]])


func test_attack_action_waits_for_move_presentation_before_combat() -> void:
	var model := RecordingBoardModel.new()
	var source := MapTile.new(0, 0)
	var interaction := MapTile.new(1, 0)
	var target := MapTile.new(2, 0)
	var action := AttackAction.new(source, interaction, target, ["1_0", "0_0"])
	var gate := PresentationGate.new()

	action.perform(model, gate.wait)

	assert_eq(model.moves.size(), 1)
	assert_eq(model.attacks.size(), 0)
	assert_eq(gate.wait_count, 1)
	gate.opened.emit()
	await wait_process_frames(1)
	assert_eq(model.attacks.size(), 1)
	assert_eq(gate.wait_count, 2)
	gate.opened.emit()
	await wait_process_frames(1)


func test_capture_action_calls_position_based_model_command() -> void:
	var model := RecordingBoardModel.new()
	var source := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)
	var action := CaptureAction.new(source, null, target, [])

	action.perform(model)

	assert_eq(model.captures, [[Vector2i(0, 0), Vector2i(1, 0)]])


func test_ability_action_passes_stable_index_and_positions() -> void:
	var model := RecordingBoardModel.new()
	var origin := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)
	var ability := Ability.new()
	ability.index = 4
	var action := UseAbilityAction.new(ability, origin, target)

	action.perform(model)

	assert_eq(model.ability_uses, [[Vector2i(0, 0), "ability4", Vector2i(1, 0)]])


func test_reserve_ap_action_updates_model_only() -> void:
	var model := RecordingBoardModel.new()
	var action := ReserveApAction.new(3)

	action.perform(model)

	assert_eq(model.reserved_ap, 3)
