extends HeroAbility
class_name ActiveHeroAbility

@export var named_icon: String = ""
@export var marker_colour: String = "green"

func _init() -> void:
    self.TYPE = "hero_active"

func get_named_icon() -> String:
    return self.named_icon

func execute(board: Board, position: Vector2i) -> void:
    super.execute(board, position)
    board.use_current_player_ap(self.ap_cost)
    self.source.use_move(1)

func is_tile_applicable(_tile: MapTile, _source_tile: MapTile) -> bool:
    return true
