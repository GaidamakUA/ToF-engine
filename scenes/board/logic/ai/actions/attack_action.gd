extends AbstractAction
class_name AttackAction

var unit: MapTile
var interaction: MapTile
var path_length: int

func _init(unit_tile: MapTile, interaction_tile: MapTile, target_tile: MapTile, path_length_val: int) -> void:
    self.unit = unit_tile
    self.interaction = interaction_tile
    self.target = target_tile
    self.path_length = path_length_val

func perform(board: Board) -> void:
    board.select_tile(self.unit.position)
    if self.interaction != null:
        board.select_tile(self.interaction.position)
        board.unselect_tile()
        await board.get_tree().create_timer(self.path_length * 0.1).timeout
        board.select_tile(self.interaction.position)
    board.select_tile(self.target.position)
    board.unselect_tile()
    await board.get_tree().create_timer(0.5).timeout

func _to_string() -> String:
    var message: String = str(self.unit.position) + " attacks " + str(self.target.position)
    if self.interaction != null:
        message += " from " + str(self.interaction.position)
    return message
