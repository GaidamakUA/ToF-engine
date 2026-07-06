extends GutTest


class FakeBoard:
	extends Board

	class FakeBoardModel:
		extends BoardModel

		var used_ap: Array[int] = []

		func use_current_player_ap(value: int) -> CommandResult:
			self.used_ap.append(value)
			return CommandResult.new("use_current_player_ap")

	var battle_calls: Array[Array] = []
	var contextual_select_count: int = 0

	func _init() -> void:
		super()
		self.board_model = FakeBoardModel.new()

	func battle(attacker_tile: MapTile, defender_tile: MapTile) -> void:
		self.battle_calls.append([attacker_tile, defender_tile])

	func _update_ap_spent_presentation() -> void:
		pass

	func show_contextual_select(_open_unit_abilities: bool = false) -> void:
		self.contextual_select_count += 1


func test_source_explicit_interaction_does_not_refresh_contextual_selection() -> void:
	var board := FakeBoard.new()
	var source := MapTile.new(0, 0)
	var target := MapTile.new(1, 0)
	var attacker := BaseUnit.new()
	var defender := BaseUnit.new()
	source.unit.set_tile(attacker)
	target.unit.set_tile(defender)

	board.handle_interaction_from_tile(source, target)

	assert_eq(board.battle_calls, [[source, target]])
	assert_eq((board.board_model as FakeBoard.FakeBoardModel).used_ap, [1])
	assert_eq(board.contextual_select_count, 0)

	attacker.free()
	defender.free()
	board.free()
