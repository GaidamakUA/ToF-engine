extends Ability
class_name SpawnUnit

@export var template_name: String = ""

func _init() -> void:
    self.TYPE = "production"

func _execute_model(model: BoardModel, source: Variant, _origin_tile: MapTile, position: Vector2i) -> Array[Vector2i]:
    var new_unit: BaseUnit = model._spawn_unit(position, self.template_name, model.get_current_side())
    if new_unit == null:
        return []
    new_unit.state.replenish_moves(new_unit.get_stats_with_modifiers())
    model.abilities.apply_passive_modifiers(new_unit)
    if model.abilities.get_initial_level(self.template_name, source) > 0:
        model.level_up_unit(position)
    return [position]
