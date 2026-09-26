extends GutTest


func test_neighbours_are_resolved_and_wrapped_from_arrays() -> void:
    var rotations := MapEditorRotations.new()
    rotations.rotations["tiles"] = PackedStringArray(["a", "b", "c"])
    rotations.types = PackedStringArray(["tiles", "units"])
    rotations.players = PackedStringArray(["blue"])

    assert_eq(rotations.get_map("a", "tiles"), {"prev": "c", "next": "b"})
    assert_eq(rotations.get_map("c", "tiles"), {"prev": "b", "next": "a"})
    assert_eq(rotations.get_type_map("units"), {"prev": "tiles", "next": "tiles"})
    assert_eq(rotations.get_player_map("blue"), {"prev": "blue", "next": "blue"})
