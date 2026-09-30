extends GutTest


func test_board_scene_script_is_a_view_with_presenter_and_model() -> void:
	var view := BoardView.new()

	assert_not_null(view.board_model)
	assert_not_null(view.presenter)
	assert_same(view.presenter.model, view.board_model)
	assert_same(view.presenter.view, view)
	assert_false(view.has_method(&"move_unit"))
	assert_false(view.has_method(&"battle"))
	assert_false(view.has_method(&"capture"))
	assert_false(view.has_method(&"execute_ability_from_tile"))

	view.free()


func test_all_board_scene_variants_instantiate() -> void:
	var scene_paths: Array[String] = [
		"res://scenes/board/board.tscn",
		"res://scenes/board_multiplayer/board_multiplayer.tscn",
		"res://scenes/board_online/board_online.tscn",
	]
	for scene_path: String in scene_paths:
		var scene: PackedScene = load(scene_path)
		assert_not_null(scene, scene_path)
		var instance: Node = scene.instantiate()
		assert_not_null(instance, scene_path)
		instance.free()
