extends HeroAbility

@export var named_icon := ""
@export var marker_colour := "green"

func _init() -> void:
	self.TYPE = "hero_active"

func execute(board: Board, position: Vector2i) -> void:
	super.execute(board, position)
	board.use_current_player_ap(self.ap_cost)
	self.source.use_move(1)

func is_tile_applicable(_tile, _source_tile) -> bool:
	return true
