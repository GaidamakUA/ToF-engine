extends Ability
class_name ActiveUnitAbility

@export var named_icon: String = ""
@export var marker_colour: String = "green"

func _init() -> void:
    self.TYPE = "active"

func get_named_icon() -> String:
    return self.named_icon

func execute(board: Board, source: Variant, origin_tile: MapTile, position: Vector2i) -> void:
    board.board_model.use_current_player_ap(self.get_cost(source))
    board._update_ap_spent_presentation()
    super.execute(board, source, origin_tile, position)
    source.use_move(1)

    if not board.state.is_current_player_ai():
        board.active_ability = null
        position = board.selected_tile.position
        board.unselect_tile()
        board.select_tile(position)

func execute_model(model: BoardModel, source: Variant, origin_tile: MapTile, position: Vector2i) -> CommandResult:
    var result := model.use_current_player_ap(self.get_cost(source))
    result.merge_from(super.execute_model(model, source, origin_tile, position))
    source.use_move(1)
    return result

func is_tile_applicable(_tile: MapTile, _origin_tile: MapTile, _source: Variant) -> bool:
    return true
