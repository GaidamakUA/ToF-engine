extends AbstractAction
class_name UseAbilityAction

var ability: Ability
var delay: float = 0.0
var origin_tile: MapTile

func _init(ability_object: Ability, origin_tile_object: MapTile, target_object: MapTile) -> void:
    self.ability = ability_object
    self.origin_tile = origin_tile_object
    self.target = target_object

func perform(model: BoardModel, wait_for_presentation: Callable = Callable()) -> void:
    model.use_ability(self.origin_tile.position, self.ability.get_key(), self.target.position)
    if wait_for_presentation.is_valid():
        await wait_for_presentation.call()


func _to_string() -> String:
    return str(self.origin_tile.position) + " uses ability on " + str(self.target.position)
