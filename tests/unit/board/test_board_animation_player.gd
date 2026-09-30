extends GutTest


const ANIMATED_ABILITIES: Array[String] = [
	"res://resources/abilities/hero/active/deep_strike.tres",
	"res://resources/abilities/hero/active/hardened_armour.tres",
	"res://resources/abilities/hero/active/infiltration.tres",
	"res://resources/abilities/hero/active/inspire.tres",
	"res://resources/abilities/hero/active/precision_strike.tres",
	"res://resources/abilities/hero/active/promote.tres",
	"res://resources/abilities/hero/active/supply.tres",
	"res://resources/abilities/hero/active/targeting_automaton.tres",
	"res://resources/abilities/unit/drop_off.tres",
	"res://resources/abilities/unit/heavy_weapon.tres",
	"res://resources/abilities/unit/long_range_shell.tres",
	"res://resources/abilities/unit/medkit.tres",
	"res://resources/abilities/unit/missile.tres",
	"res://resources/abilities/unit/heavy_missile.tres",
	"res://resources/abilities/unit/pick_up.tres",
	"res://resources/abilities/unit/rapid_response.tres",
	"res://resources/abilities/unit/repair_kit.tres",
]


func test_every_animation_kind_is_registered() -> void:
	var player := BoardAnimationPlayer.new()
	for kind: BoardAnimation.Kind in BoardAnimation.Kind.values():
		assert_true(player.has_animation(kind), BoardAnimation.Kind.keys()[kind])
	player.free()


func test_animated_ability_resources_use_registered_kinds() -> void:
	var player := BoardAnimationPlayer.new()
	for path: String in self.ANIMATED_ABILITIES:
		var ability := load(path) as Ability
		assert_not_null(ability, path)
		assert_ne(ability.animation, BoardAnimation.Kind.NONE, path)
		assert_true(player.has_animation(ability.animation), path)
	player.free()


func test_executor_keyframes_emit_impact_before_finishing() -> void:
	self._assert_executor_keyframes(
		"res://scenes/abilities/hero/active/deep_strike_executor.tscn",
		&"drop", &"_deploy_unit"
	)
	self._assert_executor_keyframes(
		"res://scenes/abilities/hero/active/precision_strike_executor.tscn",
		&"strike", &"_drop_the_bombu_man"
	)


func _assert_executor_keyframes(path: String, animation_name: StringName, impact_method: StringName) -> void:
	var executor := (load(path) as PackedScene).instantiate()
	var animation_player := executor.get_node("animations") as AnimationPlayer
	var animation: Animation = animation_player.get_animation(animation_name)
	var impact_key: Dictionary = animation.track_get_key_value(1, 0)
	var finish_key: Dictionary = animation.track_get_key_value(1, 1)
	assert_eq(impact_key["method"], impact_method, path)
	assert_eq(finish_key["method"], &"_finish", path)
	assert_lt(animation.track_get_key_time(1, 0), animation.track_get_key_time(1, 1), path)
	executor.free()
