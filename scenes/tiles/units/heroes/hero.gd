extends BaseUnit
class_name HeroUnit

var disable_active_abilities: bool = false

func register_ability(ability: Ability) -> void:
	if ability.TYPE == "hero_passive":
		self.passive_ability = ability
	if ability.TYPE == "hero_active":
		self.active_abilities.append(ability)

	super.register_ability(ability)


func has_active_ability() -> bool:
	if self.disable_active_abilities:
		return false

	return self.active_abilities.size() > 0

func has_passive_ability() -> bool:
	return self.passive_ability != null

func disable_abilities() -> void:
	self.disable_active_abilities = true

func enable_abilities() -> void:
	self.disable_active_abilities = false

func set_side_material(material: Resource) -> void:
	if material == null:
		return

	super.set_side_material(material)
	$"mesh_anchor/standard".set_surface_override_material(0, material)

func disable_shadow() -> void:
	super.disable_shadow()

	var standard_mesh: MeshInstance3D = $"mesh_anchor/standard" as MeshInstance3D
	assert(standard_mesh != null)
	standard_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func reset_position_for_tile_view() -> void:
	super.reset_position_for_tile_view()
	$"mesh_anchor/standard".hide()

func get_dict() -> Dictionary[String, Variant]:
	var new_dict: Dictionary[String, Variant] = super.get_dict()
	new_dict["disable_active_abilities"] = self.disable_active_abilities

	return new_dict

func restore_from_state(state: Dictionary) -> void:
	super.restore_from_state(state)
	self.disable_active_abilities = state["disable_active_abilities"]

func is_hero() -> bool:
	return true

func _apply_experience_modifiers(stats: Dictionary[String, int]) -> Dictionary[String, int]:
	if self.level > 0:
		stats["armor"] += 1
	if self.level > 1:
		stats["max_move"] += 1

	return stats
