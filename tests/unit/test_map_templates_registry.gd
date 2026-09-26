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

    for key: String in registry.templates:
        assert_true(registry.templates[key] is MapObjectResource, key)

    for key: String in ["ground_concrete", "blue_infantry", "modern_barracks"]:
        var source: MapObjectResource = registry.get_template_source(key)
        assert_not_null(source, key)
        var tile := registry.get_template(key)
        assert_not_null(tile, key)
        assert_eq(tile.template_name, key)
        tile.free()


func test_resource_types_select_shared_runtime_scenes() -> void:
    var registry := MapTemplates.new()
    var instances: Array[MapObject] = [
        registry.get_template("city_building_big1"),
        registry.get_template("damaged_building_big1"),
        registry.get_template("modern_barracks"),
        registry.get_template("blue_infantry"),
        registry.get_template("hero_general"),
        registry.get_template("npc_president"),
        registry.get_template("special_key"),
        registry.get_template("dummy_ground"),
    ]
    assert_true(instances[0] is GroundTile)
    assert_true(instances[1] is DamagedTile)
    assert_true(instances[2] is BaseBuilding)
    assert_true(instances[3] is BaseUnit)
    assert_true(instances[4] is HeroUnit)
    assert_true(instances[5] is BaseUnit)
    assert_true(instances[6] is GroundTile)
    assert_true(instances[7] is BaseGround)
    for instance: MapObject in instances:
        instance.free()


func test_every_resource_instantiates_through_the_shared_factory() -> void:
    var registry := MapTemplates.new()
    registry._compile_templates_list()
    for key: String in registry.templates:
        var instance: MapObject = registry.get_template(key)
        assert_not_null(instance, key)
        instance.free()
