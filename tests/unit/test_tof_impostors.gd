extends GutTest

const BAKER: GDScript = preload("res://tools/bake_tof_impostors.gd")
const GROUND_TILE_SCENE: PackedScene = preload("res://scenes/tiles/ground/ground_tile.tscn")


class RuntimeTileModel:
    extends RefCounted
    var tiles: Dictionary[Vector2i, MapTile] = {}

    func get_tile(position: Vector2i) -> MapTile:
        return self.tiles.get(position)


class RuntimeTileMap:
    extends RefCounted
    const GROUND_HEIGHT: int = Map.GROUND_HEIGHT
    var model := RuntimeTileModel.new()
    var camera: Dictionary[String, Variant] = {"camera_mode": GameCamera.MODE_TOF}
    var tiles_frames_anchor := Node3D.new()
    var tiles_terrain_anchor := Node3D.new()

    func map_to_local(position: Vector2i) -> Vector3:
        return Vector3(position.x * Map.TILE_SIZE, 0, position.y * Map.TILE_SIZE)


func test_ground_tile_uses_impostor_only_in_tof_mode() -> void:
    var resource := TileResource.new()
    resource.mesh = BoxMesh.new()
    resource.reflection_mesh = BoxMesh.new()
    resource.tof_impostor_path = "res://assets/impostors/tof/terrain/trees_3_overtile.res"
    resource.tof_impostor_origin = Vector2(12, 34)

    var tile: GroundTile = GROUND_TILE_SCENE.instantiate() as GroundTile
    add_child_autofree(tile)
    tile.configure(resource)
    tile.current_rotation = 270
    assert_null((tile.get_node("impostor") as Sprite3D).texture)
    tile.set_visual_mode(GameCamera.MODE_TOF)

    var impostor: Sprite3D = tile.get_node("impostor") as Sprite3D
    assert_true(impostor.visible)
    assert_eq(impostor.frame, 3)
    var frame_height: float = float(impostor.texture.get_height()) / float(impostor.vframes)
    assert_eq(impostor.offset, Vector2(-12, 34 - frame_height))
    assert_false((tile.get_node("mesh") as MeshInstance3D).visible)
    assert_false((tile.get_node("reflection") as MeshInstance3D).visible)

    tile.set_visual_mode(GameCamera.MODE_AW)

    assert_false(impostor.visible)
    assert_true((tile.get_node("mesh") as MeshInstance3D).visible)
    assert_true((tile.get_node("reflection") as MeshInstance3D).visible)


func test_ground_tile_without_impostor_keeps_mesh_in_tof_mode() -> void:
    var resource := TileResource.new()
    resource.mesh = BoxMesh.new()
    var tile: GroundTile = GROUND_TILE_SCENE.instantiate() as GroundTile
    add_child_autofree(tile)
    tile.configure(resource)

    tile.set_visual_mode(GameCamera.MODE_TOF)

    assert_true((tile.get_node("mesh") as MeshInstance3D).visible)
    assert_false((tile.get_node("impostor") as Sprite3D).visible)


func test_tof_impostor_uses_front_depth_without_screen_offset() -> void:
    var resource := TileResource.new()
    resource.mesh = BoxMesh.new()
    resource.tof_impostor_path = "res://assets/impostors/tof/terrain/trees_3_overtile.res"
    resource.tof_impostor_origin = Vector2(320, 328)
    var tile: GroundTile = GROUND_TILE_SCENE.instantiate() as GroundTile
    add_child_autofree(tile)
    tile.position = Vector3(10, 4, 20)
    tile.rotation.y = deg_to_rad(90)
    tile.configure(resource)
    tile.set_visual_mode(GameCamera.MODE_TOF)

    var impostor: Sprite3D = tile.get_node("impostor") as Sprite3D
    var frame_height: float = float(impostor.texture.get_height()) / float(impostor.vframes)
    assert_eq(impostor.global_position, tile.global_position + GroundTile.TOF_DEPTH_OFFSET)
    assert_eq(impostor.sorting_offset, 0.0)
    assert_eq(impostor.offset, Vector2(-320, 328 - frame_height))
    assert_eq(impostor.extra_cull_margin, 16.0)


func test_impostor_scene_uses_alpha_blending_and_cull_margin() -> void:
    var tile: GroundTile = GROUND_TILE_SCENE.instantiate() as GroundTile
    add_child_autofree(tile)
    var impostor: Sprite3D = tile.get_node("impostor") as Sprite3D

    assert_false(impostor.sorting_use_aabb_center)
    assert_eq(impostor.position, Vector3.ZERO)
    assert_eq(impostor.alpha_cut, SpriteBase3D.ALPHA_CUT_DISABLED)
    assert_eq(impostor.billboard, BaseMaterial3D.BILLBOARD_ENABLED)
    assert_false(impostor.no_depth_test)
    assert_false(impostor.fixed_size)
    assert_eq(impostor.extra_cull_margin, 16.0)


func test_decoration_and_standable_terrain_use_mesh_with_baked_shadow() -> void:
    for path: String in [
        "res://resources/decoration/flowers_1_overtile.tres",
        "res://resources/terrain/trees_16_overtile.tres",
    ]:
        var resource: TileResource = load(path) as TileResource
        var tile: GroundTile = GROUND_TILE_SCENE.instantiate() as GroundTile
        add_child_autofree(tile)
        tile.configure(resource)
        tile.set_visual_mode(GameCamera.MODE_TOF)

        var mesh_instance: MeshInstance3D = tile.get_node("mesh") as MeshInstance3D
        assert_true(mesh_instance.visible, path)
        assert_eq(mesh_instance.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, path)
        assert_false((tile.get_node("impostor") as Sprite3D).visible, path)
        assert_true((tile.get_node("impostor_shadow") as Sprite3D).visible, path)

        tile.set_visual_mode(GameCamera.MODE_AW)

        assert_eq(mesh_instance.cast_shadow, resource.mesh_cast_shadow, path)


func test_camera_mode_signal_covers_direct_and_cycled_switches() -> void:
    var camera: GameCamera = load("res://scenes/camera.tscn").instantiate() as GameCamera
    add_child_autofree(camera)
    await wait_process_frames(1)
    var observed_modes: Array[String] = []
    camera.mode_changed.connect(func(mode: String) -> void: observed_modes.append(mode))

    camera.switch_to_camera_style(GameCamera.MODE_AW)
    camera.switch_camera()

    assert_eq(observed_modes, [GameCamera.MODE_AW, GameCamera.MODE_FREE])
    assert_eq(camera.camera_mode, GameCamera.MODE_FREE)


func test_runtime_tile_events_apply_current_visual_mode() -> void:
    var map := RuntimeTileMap.new()
    add_child(map.tiles_frames_anchor)
    add_child(map.tiles_terrain_anchor)
    var player := BoardAnimationPlayer.new({"map": map})
    var no_events: Array[BoardDomainEvent] = []

    for index: int in 2:
        var position := Vector2i(index, 0)
        var tile := MapTile.new(position.x, position.y)
        map.model.tiles[position] = tile
        var object: GroundTile = GROUND_TILE_SCENE.instantiate() as GroundTile
        object.configure(load("res://resources/terrain/trees_3_overtile.tres") as TileResource)
        tile.terrain.set_tile(object)
        if index == 0:
            player._play_tile_damage(TileDamagedEvent.new(position, &"terrain", "trees3", 0), no_events)
        else:
            player._play_tile_change(TileLayerChangedEvent.new(position, &"terrain", 0), no_events)

        assert_true((object.get_node("impostor") as Sprite3D).visible)
        assert_false((object.get_node("mesh") as MeshInstance3D).visible)

    player.free()
    map.tiles_frames_anchor.free()
    map.tiles_terrain_anchor.free()


func test_baker_builds_stable_two_by_two_sheet() -> void:
    var images: Array[Image] = []
    for index: int in 4:
        var image := Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
        image.fill(Color.TRANSPARENT)
        image.set_pixel(2 + index, 2, Color8(64 * (index + 1), 0, 0, 255))
        images.append(image)

    var bounds := Rect2i(2, 1, 4, 6)
    var first: Dictionary = BAKER.build_sheet(images, bounds, Vector2i(4, 4))
    var sheet: Image = first["image"] as Image

    assert_eq(sheet.get_size(), Vector2i(8, 12))
    assert_eq(first["origin"], Vector2(2, 3))
    assert_eq(sheet.get_pixel(0, 1), Color8(64, 0, 0, 255))
    assert_eq(sheet.get_pixel(5, 1), Color8(128, 0, 0, 255))
    assert_eq(sheet.get_pixel(2, 7), Color8(192, 0, 0, 255))
    assert_eq(sheet.get_pixel(7, 7), Color8(255, 0, 0, 255))


func test_baker_rejects_incomplete_frame_sets() -> void:
    var images: Array[Image] = [Image.create_empty(2, 2, false, Image.FORMAT_RGBA8)]

    assert_true(BAKER.build_sheet(images, Rect2i(0, 0, 2, 2), Vector2i.ZERO).is_empty())


func test_baker_composites_object_over_shadow_deterministically() -> void:
    var object := Image.create_empty(2, 2, false, Image.FORMAT_RGBA8)
    object.fill(Color.TRANSPARENT)
    object.set_pixel(0, 0, Color.RED)
    var shadow := Image.create_empty(2, 2, false, Image.FORMAT_RGBA8)
    shadow.fill(Color.TRANSPARENT)
    shadow.set_pixel(0, 0, Color(0, 0, 0, 0.5))
    shadow.set_pixel(1, 0, Color(0, 0, 0, 0.5))

    var first: Image = BAKER.composite_shadow(object, shadow)

    assert_eq(first.get_pixel(0, 0), Color.RED)
    assert_almost_eq(first.get_pixel(1, 0).a, 0.5, 0.01)


func test_baker_transparent_shadow_leaves_object_unchanged() -> void:
    var object := Image.create_empty(2, 2, false, Image.FORMAT_RGBA8)
    object.fill(Color.BLUE)
    var shadow := Image.create_empty(2, 2, false, Image.FORMAT_RGBA8)
    shadow.fill(Color.TRANSPARENT)

    assert_eq(BAKER.composite_shadow(object, shadow).get_data(), object.get_data())


func test_baker_extracts_shadow_from_receiver_difference() -> void:
    var baseline := Image.create_empty(3, 3, false, Image.FORMAT_RGBA8)
    baseline.fill(Color.WHITE)
    var shadowed: Image = baseline.duplicate()
    shadowed.set_pixel(1, 1, Color(0.5, 0.5, 0.5, 1.0))

    var shadow: Image = BAKER.extract_shadow(shadowed, baseline, Rect2i(0, 0, 3, 3))

    assert_eq(shadow.get_pixel(0, 0).a, 0.0)
    assert_eq(shadow.get_pixel(1, 1).r, 0.0)
    assert_eq(shadow.get_pixel(1, 1).g, 0.0)
    assert_eq(shadow.get_pixel(1, 1).b, 0.0)
    assert_almost_eq(shadow.get_pixel(1, 1).a, 0.5 * BAKER.SHADOW_OPACITY, 0.01)


func test_baker_ignores_receiver_noise() -> void:
    var baseline := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
    baseline.fill(Color.WHITE)
    var noisy := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
    noisy.fill(Color(0.95, 0.95, 0.95, 1.0))

    var shadow: Image = BAKER.extract_shadow(noisy, baseline, Rect2i(0, 0, 1, 1))

    assert_eq(shadow.get_pixel(0, 0).a, 0.0)


func test_every_eligible_resource_has_a_generated_impostor() -> void:
    var eligible_count: int = 0
    var shadow_count: int = 0
    for prefix: String in BAKER.RESOURCE_PREFIXES:
        var directory := DirAccess.open(prefix)
        assert_not_null(directory, prefix)
        for filename: String in directory.get_files():
            if filename.get_extension() != "tres":
                continue
            var resource: MapObjectResource = load(prefix + filename) as MapObjectResource
            if resource == null or resource.mesh == null or resource is RotatingTileResource:
                continue
            eligible_count += 1
            assert_false(resource.tof_impostor_path.is_empty(), resource.resource_path)
            assert_true(FileAccess.file_exists(resource.tof_impostor_path), resource.resource_path)
            assert_gt(resource.tof_impostor_origin.x, 0.0, resource.resource_path)
            assert_gt(resource.tof_impostor_origin.y, 0.0, resource.resource_path)
            var tile_resource: TileResource = resource as TileResource
            if resource.mesh_cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF \
                and (tile_resource.unit_can_stand or prefix == BAKER.DECORATION_PREFIX):
                shadow_count += 1
                var shadow_path: String = resource.tof_impostor_path.trim_suffix(".res") + "_shadow.res"
                assert_true(FileAccess.file_exists(shadow_path), resource.resource_path)

    assert_eq(eligible_count, 203)
    assert_eq(shadow_count, 40)

    var representative: PortableCompressedTexture2D = load(
        "res://assets/impostors/tof/terrain/trees_3_overtile.res"
    ) as PortableCompressedTexture2D
    assert_not_null(representative)
    assert_eq(representative.get_width() % 2, 0)
    assert_eq(representative.get_height() % 2, 0)
    assert_true(representative.get_image().has_mipmaps())

    var representative_shadow: PortableCompressedTexture2D = load(
        "res://assets/impostors/tof/decoration/stumps_1_overtile_shadow.res"
    ) as PortableCompressedTexture2D
    assert_not_null(representative_shadow)
    assert_true(representative_shadow.get_image().has_mipmaps())
    assert_true(representative_shadow.get_image().get_used_rect().has_area())
