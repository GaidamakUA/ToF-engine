class_name HeadlessBoardScenario
extends RefCounted


class HeadlessAi:
	extends RefCounted

	var scenario: HeadlessBoardScenario

	func reserve_ap(amount: int) -> void:
		self.scenario.reserved_ap.append(amount)


class HeadlessBoardHost:
	extends RefCounted

	var scenario: HeadlessBoardScenario
	var ai: HeadlessAi = HeadlessAi.new()

	func _init(owner: HeadlessBoardScenario) -> void:
		self.scenario = owner
		self.ai.scenario = owner

	func get_tile_at(tile_position: Vector2i) -> MapTile:
		return self.scenario.get_tile(tile_position)


class MovedEventRecorder:
	extends Observer

	var scenario: HeadlessBoardScenario

	func _init(owner: HeadlessBoardScenario) -> void:
		super._init(null)
		self.scenario = owner
		self.observed_event_type = UnitMovedEvent

	func _observe(event: BaseEvent) -> void:
		self.scenario.moved_events.append(event)


class CapturedEventRecorder:
	extends Observer

	var scenario: HeadlessBoardScenario

	func _init(owner: HeadlessBoardScenario) -> void:
		super._init(null)
		self.scenario = owner
		self.observed_event_type = BuildingCapturedEvent

	func _observe(event: BaseEvent) -> void:
		self.scenario.captured_events.append(event)


var model: BoardModel = BoardModel.new()
var host: HeadlessBoardHost = HeadlessBoardHost.new(self)
var map_model: MapModel = MapModel.new()
var tiles: Dictionary[Vector2i, MapTile] = {}
var moved_events: Array[UnitMovedEvent] = []
var captured_events: Array[BuildingCapturedEvent] = []
var reserved_ap: Array[int] = []
var _nodes: Array[Node] = []
var _extra_objects: Array = []


static func from_fixture(path: String) -> HeadlessBoardScenario:
	var scenario := HeadlessBoardScenario.new()
	var payload: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(payload is Dictionary)
	scenario._load_fixture(payload)
	return scenario


static func with_adjacent_enemy() -> HeadlessBoardScenario:
	var scenario := HeadlessBoardScenario.from_fixture("res://tests/fixtures/board/headless_validation_map.json")
	var target_tile := MapTile.new(1, 1)
	scenario.tiles[target_tile.position] = target_tile
	scenario.map_model.tiles["1_1"] = target_tile
	scenario._extra_objects.append(target_tile)
	var defender := BaseUnit.new()
	defender.side = "red"
	defender.team = 1
	defender.hp = 5
	defender.max_hp = 5
	defender.armor = 0
	defender.move = 0
	defender.max_move = 0
	target_tile.unit.set_tile(defender)
	scenario.get_tile(Vector2i(0, 0)).add_neighbour(MapTile.SOUTH, target_tile)
	target_tile.add_neighbour(MapTile.NORTH, scenario.get_tile(Vector2i(0, 0)))
	scenario._nodes.append(defender)
	return scenario


func get_tile(tile_position: Vector2i) -> MapTile:
	assert(self.tiles.has(tile_position))
	return self.tiles[tile_position]


func cleanup() -> void:
	for node: Node in self._nodes:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.free()
	self._nodes.clear()
	for extra_object: Variant in self._extra_objects:
		if extra_object is Node and is_instance_valid(extra_object) and not extra_object.is_queued_for_deletion():
			extra_object.free()
	self._extra_objects.clear()


func _load_fixture(payload: Dictionary) -> void:
	self.model.events.register_observer(MovedEventRecorder.new(self))
	self.model.events.register_observer(CapturedEventRecorder.new(self))

	for player_data: Dictionary in payload["players"]:
		self.model.add_player(self._typed_dictionary(player_data))

	for tile_data: Dictionary in payload["tiles"]:
		self._load_tile(tile_data)

	for neighbour_data: Dictionary in payload["neighbours"]:
		var source_tile: MapTile = self.get_tile(self._vector2i_from_array(neighbour_data["from"]))
		var destination_tile: MapTile = self.get_tile(self._vector2i_from_array(neighbour_data["to"]))
		source_tile.add_neighbour(String(neighbour_data["direction"]), destination_tile)

	self.model.set_map_model(self.map_model)
	self.model.board = self.host


func _load_tile(tile_data: Dictionary) -> void:
	var tile_position: Vector2i = self._vector2i_from_array(tile_data["position"])
	var tile := MapTile.new(tile_position.x, tile_position.y)
	var ground := BaseTile.new()
	self.tiles[tile_position] = tile
	self.map_model.tiles[str(tile_position.x) + "_" + str(tile_position.y)] = tile
	tile.ground.set_tile(ground)
	self._nodes.append(ground)

	if tile_data.has("unit"):
		var unit_data: Dictionary = tile_data["unit"]
		var unit := BaseUnit.new()
		unit.side = String(unit_data["side"])
		unit.team = int(unit_data["team"])
		unit.max_move = int(unit_data["max_move"])
		unit.move = int(unit_data["move"])
		if unit_data.has("can_capture"):
			unit.can_capture = bool(unit_data["can_capture"])
		tile.unit.set_tile(unit)
		self._nodes.append(unit)

	if tile_data.has("building"):
		var building_data: Dictionary = tile_data["building"]
		var building := BaseBuilding.new()
		building.side = String(building_data["side"])
		building.team = int(building_data["team"])
		tile.building.set_tile(building)
		self._nodes.append(building)


func _typed_dictionary(data: Dictionary) -> Dictionary[String, Variant]:
	var typed_data: Dictionary[String, Variant] = {}
	for key: Variant in data.keys():
		var key_string: String = String(key)
		if key_string in ["team", "ap"]:
			typed_data[key_string] = int(data[key])
		else:
			typed_data[key_string] = data[key]
	return typed_data


func _vector2i_from_array(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))
