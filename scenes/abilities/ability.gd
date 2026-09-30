extends Resource
class_name Ability

var TYPE: String = "undefined"

@export var dlc_version: int = 1
@export var index: int = 0
@export var label: String = ""
@export var description: String = ""
@export var ap_cost: int = 0
@export var cooldown: int = 0
@export var ability_range: int = 0
@export var draw_range: int = 0
@export var in_line: bool = false
@export var animation: BoardAnimation.Kind = BoardAnimation.Kind.NONE

func execute_model(model: BoardModel, source: Variant, origin_tile: MapTile, position: Vector2i) -> Array[Vector2i]:
    return self._execute_model(model, source, origin_tile, position)


func _execute_model(_model: BoardModel, _source: Variant, _origin_tile: MapTile, position: Vector2i) -> Array[Vector2i]:
    return [position]

func is_visible(state: AbilityState = null, model: BoardModel = null, source: Variant = null) -> bool:
    if state != null and state.disabled:
        return false

    return self._is_visible(model, source)

func _is_visible(_model: BoardModel, _source: Variant = null) -> bool:
    return true

func is_available(_model: BoardModel = null) -> bool:
    return true

func get_cost(_source: Variant = null) -> int:
    return self.ap_cost

func get_cooldown(_source: Variant = null) -> int:
    return self.cooldown

func get_named_icon() -> String:
    return ""


func get_key() -> String:
    if not self.resource_path.is_empty():
        return self.resource_path.get_file().get_basename()
    return "ability" + str(self.index)

func is_tile_applicable(_tile: MapTile, _origin_tile: MapTile, _source: Variant) -> bool:
    return true
