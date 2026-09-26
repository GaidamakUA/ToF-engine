extends GutTest


func test_registry_uses_existing_brain_implementations() -> void:
	var registry := Brains.new()

	for key: String in ["airfield", "barracks", "factory"]:
		assert_true(registry.brains[key] is AbstractBuildingBrain, key)
	for key: String in ["heli", "npc"]:
		assert_true(registry.brains[key] is AbstractUnitBrain, key)
	assert_true(registry.brains["hero_commando"] is HeroBrain)
	assert_true(registry.brains["hero_gentleman"] is NobleBrain)
	assert_not_same(registry.brains["hero_gentleman"], registry.brains["hero_noble"])
