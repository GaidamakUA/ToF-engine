extends GutTest

const REPRESENTATIVE_KEYS: Array[String] = [
    "ground_concrete", "deco_ground_dmg3", "frame_grass1", "deco_flower1",
    "deco_rail_straight", "deco_fountain", "city_building_big1",
    "damaged_building_big1", "castle_wall_straight", "nature_big_rocks1",
    "special_key", "modern_barracks", "blue_infantry", "hero_general",
    "dummy_ground",
]


func test_literal_keys_build_the_complete_template_registry() -> void:
    var registry := MapTemplates.new()
    registry._compile_templates_list()

    for key: String in REPRESENTATIVE_KEYS:
        assert_true(registry.templates.has(key), key)

    for key: String in ["ground_concrete", "blue_infantry", "modern_barracks"]:
        var tile := registry.get_template(key)
        assert_not_null(tile, key)
        assert_eq(tile.template_name, key)
        tile.free()
