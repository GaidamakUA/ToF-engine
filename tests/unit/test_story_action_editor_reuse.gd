extends GutTest

const STORY: PackedScene = preload("res://scenes/map_editor/story/stories/story.tscn")
const POSITION_EDITOR: Script = preload("res://scenes/map_editor/story/stories/types/activate_hero.gd")
const SIDE_EDITOR: Script = preload("res://scenes/map_editor/story/stories/types/eliminate_player.gd")


func test_duplicate_actions_reuse_editors() -> void:
    var story := STORY.instantiate()
    var panels := story.get_node("edit_panels")

    for action: String in ["activate_hero", "die", "level_up"]:
        assert_same(panels.get_node(action).get_script(), POSITION_EDITOR)
    for action: String in ["eliminate_player", "revive_player"]:
        assert_same(panels.get_node(action).get_script(), SIDE_EDITOR)

    story.free()
