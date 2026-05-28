extends BaseOutcome
class_name MoveOutcome

var who: Vector2i
var where: Vector2i
var path: Array[String]

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    var source_tile: MapTile = self.board.map.model.get_tile(self.who)
    var destination_tile: MapTile = self.board.map.model.get_tile(self.where)
    var unit: BaseUnit = source_tile.unit.get_map_object()

    destination_tile.unit.set_map_object(source_tile.unit.get_map_object())
    source_tile.unit.release()

    unit.stop_animations()
    var world_position: Vector3 = Map.map_to_local(source_tile.position)
    var old_position: Vector3 = unit.get_position()
    world_position.y = old_position.y
    unit.set_position(world_position)

    unit.animate_path(self.path)

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    self.who = Vector2i(details['who'][0], details['who'][1])
    self.where = Vector2i(details['where'][0], details['where'][1])
    self.path.assign(details['path'])
