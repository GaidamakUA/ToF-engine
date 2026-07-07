class_name CombatCommands
extends RefCounted


var context: BoardCommandContext
var lifecycle: UnitLifecycleCommands
var turns: TurnCommands


func _init(command_context: BoardCommandContext, lifecycle_commands: UnitLifecycleCommands, turn_commands: TurnCommands) -> void:
	self.context = command_context
	self.lifecycle = lifecycle_commands
	self.turns = turn_commands


func attack_unit(attacker_tile: MapTile, defender_tile: MapTile) -> CommandResult:
	var result := CommandResult.new("attack_unit")
	if not self._can_attack(attacker_tile, defender_tile):
		result.command_name = "attack_unit_failed"
		return result

	var attacker: BaseUnit = attacker_tile.unit.tile
	var defender: BaseUnit = defender_tile.unit.tile

	attacker.use_move(1)
	attacker.use_attack()
	result.events.append_array(self.turns.use_current_player_ap(1).events)

	defender.receive_damage(attacker.get_attack())
	result.metadata["attack_steps"] = []
	result.metadata["destroyed_tiles"] = []
	result.metadata["attack_steps"].append({
		"attacker": attacker,
		"defender": defender,
		"attacker_tile": attacker_tile,
		"defender_tile": defender_tile,
		"destroyed": not defender.is_alive(),
	})

	if defender.is_alive():
		result.add_event(self.context.events.emit_unit_attacked(attacker, defender, attacker_tile, defender_tile))
		self._try_retaliation(result, defender_tile, attacker_tile)
	else:
		result.metadata["destroyed_tiles"].append(defender_tile)
		result.events.append_array(self.lifecycle.destroy_unit_on_tile(defender_tile, attacker).events)

	return result


func _can_attack(attacker_tile: MapTile, defender_tile: MapTile) -> bool:
	if attacker_tile == null or defender_tile == null:
		return false
	if not attacker_tile.unit.is_present() or not defender_tile.unit.is_present():
		return false

	var attacker: BaseUnit = attacker_tile.unit.tile
	var defender: BaseUnit = defender_tile.unit.tile
	if attacker == null or defender == null:
		return false
	if not attacker.has_moves() or not attacker.has_attacks():
		return false
	if not attacker.can_attack_unit(defender):
		return false
	if not self.context.state.can_current_player_afford(1):
		return false
	return true


func _try_retaliation(result: CommandResult, retaliator_tile: MapTile, target_tile: MapTile) -> void:
	var retaliator: BaseUnit = retaliator_tile.unit.tile
	var target: BaseUnit = target_tile.unit.tile
	if retaliator == null or target == null:
		return
	if not retaliator.can_retaliate(target):
		return

	retaliator.use_all_moves()
	target.receive_damage(retaliator.get_attack())
	result.delay = 0.1
	result.metadata["attack_steps"].append({
		"attacker": retaliator,
		"defender": target,
		"attacker_tile": retaliator_tile,
		"defender_tile": target_tile,
		"destroyed": not target.is_alive(),
	})

	if target.is_alive():
		result.add_event(self.context.events.emit_unit_attacked(retaliator, target, retaliator_tile, target_tile))
	else:
		result.metadata["destroyed_tiles"].append(target_tile)
		result.events.append_array(self.lifecycle.destroy_unit_on_tile(target_tile, retaliator).events)
