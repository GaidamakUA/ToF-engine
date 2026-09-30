class_name BoardStateSerializer
extends RefCounted


static func to_save_data(snapshot: BoardStateSnapshot) -> Dictionary[String, Variant]:
	var players: Array[Dictionary] = []
	for player: PlayerStateSnapshot in snapshot.match.players:
		players.append({
			"type": player.type,
			"side": player.side,
			"team": player.team,
			"ap": player.ap,
			"alive": player.alive,
			"peer_id": player.peer_id,
		})

	var tiles: Dictionary[String, Variant] = {}
	for position: Vector2i in snapshot.map.tiles:
		var tile: TileStateSnapshot = snapshot.map.get_tile(position)
		tiles[_position_key(position)] = {
			"ground": _map_object_to_dictionary(tile.ground),
			"frame": _map_object_to_dictionary(tile.frame),
			"decoration": _map_object_to_dictionary(tile.decoration),
			"terrain": _map_object_to_dictionary(tile.terrain),
			"building": _building_to_dictionary(tile.building),
			"unit": _unit_to_dictionary(tile.unit),
			"damage": _map_object_to_dictionary(tile.damage),
		}

	return {
		"turn": snapshot.match.turn,
		"active_player": snapshot.match.current_player,
		"players": players,
		"tiles": tiles,
		"triggers": snapshot.scenario.triggers,
		"objectives": snapshot.scenario.objectives,
		"player_moved": snapshot.match.has_player_moved,
		"turn_limit": snapshot.match.turn_limit,
		"time_limit": snapshot.match.time_limit,
	}


static func match_from_save_data(data: Dictionary) -> MatchStateSnapshot:
	var players: Array[PlayerStateSnapshot] = []
	var player_data_list: Array = data.get("players", [])
	for player_data: Dictionary in player_data_list:
		players.append(PlayerStateSnapshot.new(
			String(player_data.get("type", State.PLAYER_HUMAN)),
			String(player_data.get("side", "neutral")),
			player_data.get("team"),
			int(player_data.get("ap", 0)),
			bool(player_data.get("alive", true)),
			player_data.get("peer_id")
		))
	return MatchStateSnapshot.new(
		int(data.get("active_player", 0)), int(data.get("turn", 1)),
		bool(data.get("player_moved", false)), players,
		int(data.get("turn_limit", 0)), int(data.get("time_limit", 0))
	)


static func _map_object_to_dictionary(object: MapObjectStateSnapshot) -> Dictionary[String, Variant]:
	if object == null:
		return {"tile": null, "rotation": 0}
	return {"tile": object.template_key, "rotation": object.rotation}


static func _building_to_dictionary(building: BuildingStateSnapshot) -> Dictionary[String, Variant]:
	if building == null:
		return {"tile": null, "rotation": 0}
	var result: Dictionary[String, Variant] = _map_object_to_dictionary(building)
	result["id"] = building.id
	result["side"] = building.side
	result["abilities"] = _abilities_to_dictionary(building.abilities)
	return result


static func _unit_to_dictionary(unit: UnitStateSnapshot) -> Dictionary[String, Variant]:
	if unit == null:
		return {"tile": null, "rotation": 0}
	var result: Dictionary[String, Variant] = _map_object_to_dictionary(unit)
	result["id"] = unit.id
	result["side"] = unit.side
	result["team"] = unit.team
	result["modifiers"] = unit.modifiers
	result["ai_paused"] = unit.ai_paused
	result["disable_active_abilities"] = unit.disable_active_abilities
	result["stats"] = {
		"hp": unit.hp,
		"max_hp": unit.max_hp,
		"move": unit.move,
		"max_move": unit.max_move,
		"attack": unit.attack,
		"armor": unit.armor,
		"attacks": unit.attacks,
		"max_attacks": unit.max_attacks,
		"level": unit.level,
		"experience": unit.experience,
		"kills": unit.kills,
	}
	result["abilities"] = _abilities_to_dictionary(unit.abilities)
	if not unit.scripting_tags.is_empty():
		result["tags"] = unit.scripting_tags
	if unit.passenger != null:
		result["passenger"] = _unit_to_dictionary(unit.passenger)
	return result


static func _abilities_to_dictionary(abilities: Array[AbilityStateSnapshot]) -> Dictionary[String, Array]:
	var result: Dictionary[String, Array] = {}
	for ability: AbilityStateSnapshot in abilities:
		result["ability" + str(ability.index)] = [ability.disabled, ability.cooldown]
	return result


static func _position_key(position: Vector2i) -> String:
	return str(position.x) + "_" + str(position.y)
