extends AbstractAction
class_name UseAbilityAction

var ability: Ability
var delay: float = 0.0

func _init(ability_object: Ability, target_object: MapTile) -> void:
    self.ability = ability_object
    self.target = target_object

func perform(board: Board) -> void:
    board.selected_tile = self.ability.active_source_tile
    if board.selected_tile.building.is_present():
        board._activate_production_ability(self.ability)
    else:
        board._activate_ability(self.ability)
    board.selected_tile = null
    board.select_tile(self.target.position)
    board.unselect_tile()
    if self.delay > 0:
        await board.get_tree().create_timer(self.delay).timeout


func _to_string() -> String:
    return str(self.ability.active_source_tile.position) + " uses ability on " + str(self.target.position)
