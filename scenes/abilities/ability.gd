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

func execute(board: Board, source: Variant, origin_tile: MapTile, position: Vector2i) -> void:
    self._execute(board, source, origin_tile, position)
    board.events.emit_ability_used(self, position)

func _execute(_board: Board, _source: Variant, _origin_tile: MapTile, _position: Vector2i) -> void:
    return

func is_visible(state: AbilityState = null, _board: Board = null, source: Variant = null) -> bool:
    if state != null and state.disabled:
        return false

    return self._is_visible(_board, source)

func _is_visible(_board: Board, _source: Variant = null) -> bool:
    return true

func is_available(_board: Board = null) -> bool:
    return true

func get_cost(_source: Variant = null) -> int:
    return self.ap_cost

func get_cooldown(_source: Variant = null) -> int:
    return self.cooldown

func get_named_icon() -> String:
    return ""

func is_tile_applicable(_tile: MapTile, _origin_tile: MapTile, _source: Variant) -> bool:
    return true
