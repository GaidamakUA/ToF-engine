extends GroundTile


func _process(delta: float) -> void:
    $"mesh".rotate_y(-PI * delta)
