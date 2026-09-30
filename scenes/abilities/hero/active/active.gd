extends HeroAbility
class_name ActiveHeroAbility

@export var named_icon: String = ""
@export var marker_colour: String = "green"

func _init() -> void:
    self.TYPE = "hero_active"

func get_named_icon() -> String:
    return self.named_icon

func is_tile_applicable(_tile: MapTile, _origin_tile: MapTile, _source: Variant) -> bool:
    return true
