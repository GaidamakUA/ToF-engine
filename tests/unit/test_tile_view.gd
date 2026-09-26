extends GutTest


func test_unit_preview_contains_only_its_mesh() -> void:
    var view := TileView.new()
    var resource := UnitResource.new()
    resource.mesh = ArrayMesh.new()

    var preview: Node3D = view._create_preview(resource)

    assert_false(preview is MapObject)
    assert_eq(preview.get_child_count(), 1)
    assert_same((preview.get_child(0) as MeshInstance3D).mesh, resource.mesh)
    preview.free()
    view.free()


func test_preview_uses_only_resource_visual_data() -> void:
    var view := TileView.new()
    var source := MapObjectResource.new()
    source.mesh = BoxMesh.new()
    source.mesh_transform = Transform3D(Basis.from_euler(Vector3(0, PI, 0)), Vector3(1, 4, 2))
    source.mesh_cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    source.mesh_material_override = StandardMaterial3D.new()
    source.reflection_mesh = SphereMesh.new()

    var preview: Node3D = view._create_preview(source)

    assert_false(preview is MapObject)
    assert_eq(preview.get_child_count(), 2)
    var mesh: MeshInstance3D = preview.get_child(0) as MeshInstance3D
    assert_same(mesh.mesh, source.mesh)
    assert_eq(mesh.position, Vector3(1, 0, 2))
    assert_eq(mesh.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
    assert_same(mesh.material_override, source.mesh_material_override)
    assert_same((preview.get_child(1) as MeshInstance3D).mesh, source.reflection_mesh)
    preview.free()
    view.free()


func test_story_dialog_applies_material_to_every_actor_mesh() -> void:
    var dialog: StoryDialogPanel = load("res://scenes/ui/board/story_dialog.tscn").instantiate() as StoryDialogPanel
    var templates := MapTemplates.new()
    var preview_material: Material = templates.get_side_material("black") as Material
    add_child_autofree(dialog)

    dialog.set_actor({
        "name": "Commando",
        "side": "left",
        "portrait_source": templates.get_template_source("hero_commando"),
        "portrait_material": preview_material,
    })
    await wait_process_frames(1)

    var view: TileView = dialog.get_node("background/actor_left/actor_view") as TileView
    assert_false(view.tile is MapObject)
    var meshes: Array[Node] = view.tile.find_children("*", "MeshInstance3D", true, false)
    assert_gt(meshes.size(), 0)
    for mesh: MeshInstance3D in meshes:
        assert_same(mesh.material_override, preview_material, mesh.name)

    dialog.set_actor({
        "name": "Infantry",
        "side": "right",
        "portrait_source": templates.get_template_source("blue_infantry"),
        "portrait_material": preview_material,
    })
    assert_null(view.tile)
    var right_view: TileView = dialog.get_node("background/actor_right/actor_view") as TileView
    var right_mesh: MeshInstance3D = right_view.tile.get_child(0) as MeshInstance3D
    assert_not_null(right_mesh)
    assert_same(right_mesh.material_override, preview_material)
