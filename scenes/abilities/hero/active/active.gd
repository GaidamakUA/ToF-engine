extends HeroAbility
class_name ActiveHeroAbility

@export var named_icon: String = ""
@export var marker_colour: String = "green"

func _init() -> void:
    self.TYPE = "hero_active"

func get_named_icon() -> String:
    return self.named_icon

func execute(board: Board, source: Variant, origin_tile: MapTile, position: Vector2i) -> void:
    super.execute(board, source, origin_tile, position)
    board.board_model.use_current_player_ap(self.ap_cost)
    board._update_ap_spent_presentation()
    source.use_move(1)

func execute_model(model: BoardModel, source: Variant, origin_tile: MapTile, position: Vector2i) -> CommandResult:
    var result := super.execute_model(model, source, origin_tile, position)
    result.merge_from(model.use_current_player_ap(self.ap_cost))
    source.use_move(1)
    return result

func is_tile_applicable(_tile: MapTile, _origin_tile: MapTile, _source: Variant) -> bool:
    return true
