extends Ability
class_name ActiveUnitAbility

@export var named_icon: String = ""
@export var marker_colour: String = "green"

func _init() -> void:
    self.TYPE = "active"

func get_named_icon() -> String:
    return self.named_icon

func execute(board: Board, position: Vector2i) -> void:
    board.use_current_player_ap(self.get_cost())
    super.execute(board, position)
    self.source.use_move(1)

    if not board.state.is_current_player_ai():
        board.active_ability = null
        position = board.selected_tile.position
        board.unselect_tile()
        board.select_tile(position)

func is_tile_applicable(_tile: MapTile, _source_tile: MapTile) -> bool:
    return true
