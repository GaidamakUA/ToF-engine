extends GutTest


func test_damage_chain_uses_resources_and_shared_runtime_scene() -> void:
    var registry := MapTemplates.new()
    var base: TileResource = registry.get_template_source("city_building_small1") as TileResource
    var damaged: DamageTileResource = registry.get_template_source("damaged_building_small1") as DamageTileResource
    var destroyed: DamageTileResource = registry.get_template_source("destroyed_building_small1") as DamageTileResource

    assert_eq(base.next_damage_stage_template, "damaged_building_small1")
    assert_eq(damaged.next_damage_stage_template, "destroyed_building_small1")
    assert_eq(damaged.base_stage_template, "city_building_small1")
    assert_eq(destroyed.next_damage_stage_template, "")
    assert_eq(destroyed.base_stage_template, "city_building_small1")
    assert_false(damaged.is_smoking)
    assert_true(destroyed.is_smoking)

    var damaged_tile: DamagedTile = registry.get_template("damaged_building_small1") as DamagedTile
    var destroyed_tile: DamagedTile = registry.get_template("destroyed_building_small1") as DamagedTile
    assert_not_null(damaged_tile)
    assert_not_null(destroyed_tile)
    assert_same((damaged_tile.get_node("mesh") as MeshInstance3D).mesh, damaged.mesh)
    assert_same((destroyed_tile.get_node("mesh") as MeshInstance3D).mesh, destroyed.mesh)
    damaged_tile.free()
    add_child_autofree(destroyed_tile)
    await wait_process_frames(1)
    assert_true(destroyed_tile.smoke.emitting)
    assert_not_null(destroyed_tile.explosion)


func test_damage_resources_keep_serialized_layer_state() -> void:
    var registry := MapTemplates.new()
    var map_tile := MapTile.new(0, 0)
    var terrain: BaseTile = registry.get_template("destroyed_building_small1") as BaseTile
    var crater: BaseTile = registry.get_template(MapTemplates.DECO_GROUND_DMG_1) as BaseTile
    terrain.current_rotation = 270
    crater.current_rotation = 90
    map_tile.terrain.set_tile(terrain)
    map_tile.damage.set_tile(crater)

    var state: Dictionary[String, Variant] = map_tile.get_dict()
    assert_eq(state["terrain"]["tile"], "destroyed_building_small1")
    assert_eq(state["terrain"]["rotation"], 270)
    assert_eq(state["damage"]["tile"], MapTemplates.DECO_GROUND_DMG_1)
    assert_eq(state["damage"]["rotation"], 90)

    map_tile.terrain.release()
    map_tile.damage.release()
    terrain.free()
    crater.free()


func test_damage_preview_uses_resource_mesh_without_runtime_scene() -> void:
    var registry := MapTemplates.new()
    var source: DamageTileResource = registry.get_template_source("destroyed_building_small1") as DamageTileResource
    var view := TileView.new()

    var preview: Node3D = view._create_preview(source)

    assert_eq(preview.get_child_count(), 1)
    assert_same((preview.get_child(0) as MeshInstance3D).mesh, source.mesh)
    preview.free()
    view.free()


func test_every_damage_chain_resolves_and_restores_to_base() -> void:
    var registry := MapTemplates.new()
    registry._compile_templates_list()

    for key: String in registry.templates:
        var resource: TileResource = registry.templates[key] as TileResource
        if resource == null or resource.next_damage_stage_template == "":
            continue
        var next: TileResource = registry.get_template_source(resource.next_damage_stage_template) as TileResource
        assert_not_null(next, "%s next stage" % key)

    for key: String in registry._damaged_city_templates:
        var resource: DamageTileResource = registry._damaged_city_templates[key] as DamageTileResource
        assert_not_null(resource, key)
        assert_ne(resource.base_stage_template, "", "%s base stage" % key)
        assert_true(registry.templates.has(resource.base_stage_template), "%s base resolves" % key)
        if key.begins_with("damaged_"):
            assert_ne(resource.next_damage_stage_template, "", "%s destroyed stage" % key)
            var destroyed: DamageTileResource = registry.get_template_source(resource.next_damage_stage_template) as DamageTileResource
            assert_not_null(destroyed, "%s destroyed resolves" % key)
            assert_eq(destroyed.base_stage_template, resource.base_stage_template, "%s restoration target" % key)
            assert_eq(destroyed.next_damage_stage_template, "", "%s chain ends" % key)
