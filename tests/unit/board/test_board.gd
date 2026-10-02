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


func test_building_coin_effect_only_spawns_for_positive_ap() -> void:
	var view := BoardView.new()
	var map := Map.new()
	var effects_anchor := Node3D.new()
	self.add_child(effects_anchor)
	view.map = map
	view.explosion_anchor = effects_anchor
	view.state.add_player(State.PLAYER_HUMAN, "blue")
	view.state.add_player(State.PLAYER_AI, "red")
	map.model.tiles.clear()

	var producing_tile := MapTile.new(2, 3)
	var producing_building := BaseBuilding.new()
	producing_building.side = "blue"
	producing_building.ap_gain = 5
	producing_tile.building.set_tile(producing_building)
	map.model.tiles["2_3"] = producing_tile

	var idle_tile := MapTile.new(4, 5)
	var idle_building := BaseBuilding.new()
	idle_building.side = "blue"
	idle_building.ap_gain = 0
	idle_tile.building.set_tile(idle_building)
	map.model.tiles["4_5"] = idle_tile

	var ai_tile := MapTile.new(6, 7)
	var ai_building := BaseBuilding.new()
	ai_building.side = "red"
	ai_building.ap_gain = 5
	ai_tile.building.set_tile(ai_building)
	map.model.tiles["6_7"] = ai_tile

	view._show_building_coin_effects()

	assert_eq(effects_anchor.get_child_count(), 1)
	var coin := effects_anchor.get_child(0) as Node3D
	assert_eq(coin.position, Vector3(16, 0, 24))
	assert_true((coin.get_node("animations") as AnimationPlayer).is_playing())
	await self.wait_process_frames(2)
	assert_gt(coin.position.y, 0.0)

	coin.free()
	view.state.current_player = 1
	view._show_building_coin_effects()
	assert_eq(effects_anchor.get_child_count(), 1)
	coin = effects_anchor.get_child(0) as Node3D
	assert_eq(coin.position, Vector3(48, 0, 56))

	coin.free()
	effects_anchor.free()
	producing_tile.building.release()
	idle_tile.building.release()
	ai_tile.building.release()
	producing_building.free()
	idle_building.free()
	ai_building.free()
	map.free()
	view.free()
