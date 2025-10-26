class_name AbstractBrain

func get_actions(_entity_tile: MapTile,
                _enemy_buildings: Array[MapTile],
                _enemy_units: Array[MapTile],
                _own_buildings: Array[MapTile],
                _own_units: Array[MapTile],
                _ap: int,
                _board: Board) -> Array[AbstractAction]:
    return []
