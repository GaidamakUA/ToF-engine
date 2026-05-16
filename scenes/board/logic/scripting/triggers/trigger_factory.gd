class_name TriggerFactory

func get_trigger(name: String) -> BaseTrigger:
    match name:
        'building_lost':
            return BuildingLostTrigger.new()
        'turn':
            return TurnTrigger.new()
        'move':
            return MoveTrigger.new()
        'deploy':
            return DeployTrigger.new()
        'claim':
            return ClaimTrigger.new()
        'decimate':
            return DecimateTrigger.new()
        'assassination':
            return AssassinationTrigger.new()
        'attacked':
            return AttackedTrigger.new()
        'resources':
            return ResourcesTrigger.new()
        'ability':
            return AbilityTrigger.new()

    return null
