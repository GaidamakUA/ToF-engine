class_name HeadlessBoardScenario
extends RefCounted


var map_model: MapModel = MapModel.new()
var model: BoardModel = BoardModel.new(self.map_model)
var updates: Array[BoardStateSnapshot] = []
var domain_events: Array[BoardDomainEvent] = []
var _nodes: Array[Node] = []


static func from_fixture(path: String) -> HeadlessBoardScenario:
	var scenario := HeadlessBoardScenario.new()
	var payload: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(payload is Dictionary)
	scenario._load_fixture(payload)
	return scenario


func get_tile(position: Vector2i) -> MapTile:
	return self.map_model.get_tile(position)


func place_unit(position: Vector2i, side: String, team: int, hp: int = 10) -> BaseUnit:
	var unit := BaseUnit.new()
	unit.side = side
	unit.team = team
	unit.max_hp = hp
	unit.state.reset_from_stats(unit.get_stats_with_modifiers())
	self.get_tile(position).unit.set_tile(unit)
	self._nodes.append(unit)
	self.model.set_map_model(self.map_model)
	return unit


func cleanup() -> void:
	for node: Node in self._nodes:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.free()
	self._nodes.clear()


func _load_fixture(payload: Dictionary) -> void:
	self.model.updated.connect(self._on_model_updated)
	for player_data: Dictionary in payload["players"]:
		self.model.add_player(
			String(player_data["type"]), String(player_data["side"]), bool(player_data["alive"]),
			player_data["team"], int(player_data.get("ap", 0)), player_data.get("peer_id")
		)
	for tile_data: Dictionary in payload["tiles"]:
		self._load_tile(tile_data)
	for neighbour_data: Dictionary in payload["neighbours"]:
		var source: MapTile = self.get_tile(self._vector2i_from_array(neighbour_data["from"]))
		var destination: MapTile = self.get_tile(self._vector2i_from_array(neighbour_data["to"]))
		source.add_neighbour(String(neighbour_data["direction"]), destination)
	self.model.set_map_model(self.map_model)
	self.model.publish_state()


func _load_tile(tile_data: Dictionary) -> void:
	var position: Vector2i = self._vector2i_from_array(tile_data["position"])
	var tile: MapTile = self.get_tile(position)
	var ground := BaseTile.new()
	tile.ground.set_tile(ground)
	self._nodes.append(ground)

	if tile_data.has("unit"):
		var data: Dictionary = tile_data["unit"]
		var unit := BaseUnit.new()
		unit.side = String(data["side"])
		unit.team = int(data["team"])
		unit.max_hp = int(data.get("max_hp", 10))
		unit.max_move = int(data["max_move"])
		unit.attack = int(data.get("attack", 7))
		unit.armor = int(data.get("armor", 2))
		unit.can_capture = bool(data.get("can_capture", false))
		unit.state.reset_from_stats(unit.get_stats_with_modifiers())
		unit.move = int(data["move"])
		tile.unit.set_tile(unit)
		self._nodes.append(unit)

	if tile_data.has("building"):
		var data: Dictionary = tile_data["building"]
		var building := BaseBuilding.new()
		building.side = String(data["side"])
		building.team = int(data["team"])
		building.require_crew = bool(data.get("require_crew", false))
		tile.building.set_tile(building)
		self._nodes.append(building)


func _on_model_updated(snapshot: BoardStateSnapshot, events: Array[BoardDomainEvent]) -> void:
	self.updates.append(snapshot)
	self.domain_events.append_array(events)


func _vector2i_from_array(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))
