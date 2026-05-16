class_name OutcomeFactory

func get_outcome(name: String) -> BaseOutcome:
    match name:
        'story':
            return StoryOutcome.new()
        'activate_hero':
            return ActivateHeroOutcome.new()
        'ap':
            return ApOutcome.new()
        'attack':
            return AttackOutcome.new()
        'ban_unit':
            return BanUnitOutcome.new()
        'camera':
            return CameraOutcome.new()
        'claim':
            return ClaimOutcome.new()
        'despawn':
            return DespawnOutcome.new()
        'die':
            return DieOutcome.new()
        'eliminate_player':
            return EliminatePlayerOutcome.new()
        'end_game':
            return EndGameOutcome.new()
        'hero_ability':
            return HeroAbilityOutcome.new()
        'level_up':
            return LevelUpOutcome.new()
        'lock':
            return LockHudOutcome.new()
        'message':
            return MessageOutcome.new()
        'move':
            return MoveOutcome.new()
        'objective':
            return ObjectiveOutcome.new()
        'pause_ai':
            return PauseAiOutcome.new()
        'revive_player':
            return RevivePlayerOutcome.new()
        'side':
            return SideOutcome.new()
        'spawn':
            return SpawnOutcome.new()
        'target_vip':
            return TargetVipOutcome.new()
        'terrain_add':
            return TerrainAddOutcome.new()
        'terrain_remove':
            return TerrainRemoveOutcome.new()
        'tether':
            return TetherOutcome.new()
        'trigger':
            return TriggerOutcome.new()
        'trigger_group':
            return TriggerGroupOutcome.new()
        'unlock':
            return UnlockHudOutcome.new()
        'use_ability':
            return UseAbilityOutcome.new()

    return null
