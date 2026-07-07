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

func execute_model(model: BoardModel, source: Variant, origin_tile: MapTile, position: Vector2i) -> CommandResult:
    var result: CommandResult = self._execute_model(model, source, origin_tile, position)
    if result == null:
        result = CommandResult.new("use_ability")
    if result.command_name == "":
        result.command_name = "use_ability"
    if result.command_name != "use_ability_failed":
        var event := AbilityUsedEvent.new()
        event.ability = self
        event.target = position
        model.events.emit_event(event)
        result.add_event(event)
    return result

func _execute(_board: Board, _source: Variant, _origin_tile: MapTile, _position: Vector2i) -> void:
    return

func _execute_model(_model: BoardModel, _source: Variant, _origin_tile: MapTile, _position: Vector2i) -> CommandResult:
    return CommandResult.new("use_ability")

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


func _append_effect(result: CommandResult, effect: Dictionary) -> void:
    var effects: Array = result.metadata.get("effects", [])
    effects.append(effect)
    result.metadata["effects"] = effects


func _append_tile_effect(result: CommandResult, effect_type: String, tile: MapTile) -> void:
    self._append_effect(result, {
        "type": effect_type,
        "tile": tile,
    })


func _append_projectile_effect(result: CommandResult, effect_type: String, origin_tile: MapTile, target_tile: MapTile, tween_time: float) -> void:
    self._append_effect(result, {
        "type": effect_type,
        "origin": origin_tile,
        "target": target_tile,
        "tween_time": tween_time,
    })
