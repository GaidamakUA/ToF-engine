extends GutTest

const EXPECTED_PIVOTS: Dictionary = {
    "blue_heli": [Vector3.ZERO],
    "blue_scout": [Vector3(0, 1.7, 0.6)],
    "red_heli": [Vector3(0, 1.4, -0.2)],
    "red_scout": [Vector3(0, 1.3, 0.1)],
    "green_heli": [Vector3(-1.3, 1.4, 0.1), Vector3(1.2, 1.4, 0.1)],
    "green_scout": [Vector3(-1, 0.9, 0.8), Vector3(1, 0.9, 0.8), Vector3(0, 0.9, -0.8)],
    "yellow_heli": [
        Vector3(1.25, 1.3, -0.25), Vector3(-1.25, 1.3, -0.25),
        Vector3(-0.7, 1.1, -0.6), Vector3(0.7, 1.1, -0.6),
    ],
    "yellow_scout": [Vector3(0, 1.2, 0)],
}


func test_all_helicopter_resources_restore_historical_rotors() -> void:
    var templates := MapTemplates.new()

    for key: String in self.EXPECTED_PIVOTS:
        var source := templates.get_template_source(key) as UnitResource
        var expected_pivots: Array = self.EXPECTED_PIVOTS[key]
        assert_eq(source.rotors.size(), expected_pivots.size(), key)

        for index: int in source.rotors.size():
            var rotor: RotorResource = source.rotors[index]
            assert_not_null(rotor.mesh, "%s rotor %s" % [key, index])
            assert_eq(rotor.pivot_transform.origin, expected_pivots[index], key)
            assert_eq(rotor.mesh_transform.origin, self._expected_mesh_origin(key, index), key)
            assert_eq(rotor.rotation_axis, self._expected_axis(key, index), key)
            assert_eq(rotor.mesh.resource_path, self._expected_mesh_path(key, index), key)

        var unit := templates.get_template(key) as BaseUnit
        var body := unit.get_node("mesh_anchor/mesh") as MeshInstance3D
        assert_eq(unit._rotor_pivots.size(), expected_pivots.size(), key)
        assert_eq(body.get_child_count(), expected_pivots.size(), key)
        unit.free()


func test_runtime_rotors_reconfigure_and_rotate_on_both_axes() -> void:
    var templates := MapTemplates.new()
    var source := templates.get_template_source("yellow_heli") as UnitResource
    var unit := templates.get_template("yellow_heli") as BaseUnit
    var body := unit.get_node("mesh_anchor/mesh") as MeshInstance3D

    unit.configure(source)
    assert_eq(unit._rotor_pivots.size(), 4)
    assert_eq(body.get_child_count(), 4)
    for index: int in source.rotors.size():
        var rotor_mesh := unit._rotor_pivots[index].get_child(0) as MeshInstance3D
        assert_same(rotor_mesh.mesh, source.rotors[index].mesh)
        assert_same(rotor_mesh.material_override, BaseUnit.ROTOR_MATERIAL)

    unit._process(0.125)
    assert_lt(
        (unit._rotor_pivots[0].basis * Vector3.RIGHT - Vector3.FORWARD).length(),
        0.001
    )
    assert_lt(
        (unit._rotor_pivots[2].basis * Vector3.RIGHT - Vector3.UP).length(),
        0.001
    )
    unit.free()


func test_tile_view_builds_animates_and_clears_rotors() -> void:
    var templates := MapTemplates.new()
    var view := TileView.new()
    var yellow := templates.get_template_source("yellow_heli") as UnitResource
    var preview := view._create_preview(yellow)
    var body := preview.get_child(0) as MeshInstance3D

    assert_eq(view._rotor_pivots.size(), 4)
    assert_eq(body.get_child_count(), 4)
    view._process(0.125)
    assert_lt(
        (view._rotor_pivots[2].basis * Vector3.RIGHT - Vector3.UP).length(),
        0.001
    )

    view.tile = preview
    view.clear()
    assert_eq(view._rotor_pivots.size(), 0)

    var blue := templates.get_template_source("blue_scout") as UnitResource
    var replacement := view._create_preview(blue)
    assert_eq(view._rotor_pivots.size(), 1)
    replacement.free()
    view.free()


func test_impostor_priority_includes_rotors_without_recoloring_them() -> void:
    var unit := MapTemplates.new().get_template("yellow_heli") as BaseUnit
    unit.set_side_material(load("res://assets/materials/arne32_yellow.tres") as Material)
    unit.set_impostor_priority(true)

    var meshes := unit._get_impostor_priority_meshes()
    assert_eq(meshes.size(), 5)
    for mesh: MeshInstance3D in meshes:
        assert_not_null(mesh.material_overlay)
    for pivot: Node3D in unit._rotor_pivots:
        var rotor_mesh := pivot.get_child(0) as MeshInstance3D
        assert_same(rotor_mesh.material_override, BaseUnit.ROTOR_MATERIAL)

    unit.set_impostor_priority(false)
    for mesh: MeshInstance3D in meshes:
        assert_null(mesh.material_overlay)
    unit.free()


func _expected_axis(key: String, index: int) -> Vector3:
    if key == "yellow_heli" and index >= 2:
        return Vector3.BACK
    return Vector3.UP


func _expected_mesh_origin(key: String, index: int) -> Vector3:
    if key == "yellow_heli" and index < 2:
        return Vector3(-0.05, 0, -0.05)
    return Vector3.ZERO


func _expected_mesh_path(key: String, index: int) -> String:
    var side := key.get_slice("_", 0)
    if key == "yellow_heli":
        var rotor_name := "heli_rotor_vertical.obj" if index < 2 else "heli_rotor_horizontal.obj"
        return "res://assets/units/yellow/%s" % rotor_name
    var rotor_name := "scout_heli_rotor.obj" if key.ends_with("_scout") else "heli_rotor.obj"
    return "res://assets/units/%s/%s" % [side, rotor_name]
