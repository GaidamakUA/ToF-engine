class_name RadialAbilities

var tile_view_template: PackedScene = preload("res://scenes/map_editor/tile_view.tscn")


func is_object_without_abilities(_board: Variant, context_object: Variant, include_disabled: bool = false) -> bool:
    if context_object == null:
        return false

    if context_object is BaseBuilding:
        if include_disabled:
            return context_object.abilities.size() == 0
        for ability: Ability in context_object.abilities:
            if not context_object.is_ability_disabled(ability):
                return false
        return true

    if context_object is BaseUnit:
        if not context_object.has_moves():
            return true

        return not context_object.has_active_ability()

    return false


func fill_radial_with_abilities(board: Board, radial: Radial, context_object: Variant) -> void:
    if context_object is BaseBuilding:
        self.fill_radial_with_building_abilities(board, radial, context_object)
    if context_object is BaseUnit:
        self.fill_radial_with_unit_abilities(board, radial, context_object)


func fill_radial_with_building_abilities(board: Board, radial: Radial, building: BaseBuilding) -> void:
    radial.set_field(board.ui.icons.cross.instantiate(), "TR_CLOSE", 6, board, "toggle_radial_menu")

    var icon: Variant
    var label: String

    for ability: Variant in building.abilities:
        if ability.TYPE == "production" and building.is_ability_visible(ability, board):
            var icon_model: MapObject = board.map.templates.get_template(ability.template_name)
            var ap_cost: int = ability.get_cost(building)

            ap_cost = board.abilities.get_modified_cost(ap_cost, ability.template_name, building)

            icon_model.set_side_material(board.map.templates.get_side_material(building.side))
            icon = tile_view_template.instantiate()
            icon.hide_background()
            icon.is_side_tile = false
            icon.viewport_size = 20
            label = tr(ability.label)
            label += "\n" + str(ap_cost) + " " + tr("TR_AP")
            if not board.state.can_current_player_afford(ap_cost):
                label += "\n" + tr("TR_NOT_ENOUGH_AP")
                radial.set_field_disabled(ability.index, "")

            radial.set_field(icon, label, ability.index, board, "activate_production_ability", [ability])
            icon.set_tile(icon_model, 0)

func fill_radial_with_unit_abilities(board: Board, radial: Radial, unit: BaseUnit) -> void:
    radial.set_field(board.ui.icons.cross.instantiate(), "TR_CLOSE", 6, board, "toggle_radial_menu")
    var label: String

    for ability: Variant in unit.active_abilities:
        if unit.is_ability_visible(ability, board):
            label = tr(ability.label)
            var cost: int = ability.get_cost(unit)
            if cost > 0:
                label += "\n" + str(cost) + " " + tr("TR_AP")
                if not board.state.can_current_player_afford(cost):
                    label += "\n" + tr("TR_NOT_ENOUGH_AP")
                    radial.set_field_disabled(ability.index, "")
            radial.set_field(board.ui.icons.get_named_icon(ability.get_named_icon()), label, ability.index, board, "activate_ability", [ability])

            if unit.is_ability_on_cooldown(ability):
                radial.set_field_disabled(ability.index, unit.get_ability_cooldown(ability))

func fill_radial_with_ability_bans(editor: Variant, radial: Radial, context_object: Variant) -> void:
    if context_object is BaseBuilding:
        self.fill_radial_with_building_abilities_bans(editor, radial, context_object)

func fill_radial_with_building_abilities_bans(editor: Variant, radial: Radial, building: BaseBuilding) -> void:
    radial.set_field(editor.ui.icons.cross.instantiate(), "TR_CLOSE", 6, editor, "toggle_radial_menu")

    var icon: Variant
    var label: String

    for ability: Variant in building.abilities:
        if ability.TYPE == "production":
            var icon_model: MapObject = editor.map.templates.get_template(ability.template_name)

            icon_model.set_side_material(editor.map.templates.get_side_material(building.side))
            icon = tile_view_template.instantiate()
            icon.hide_background()
            icon.is_side_tile = false
            icon.viewport_size = 20
            icon.set_tile(icon_model, 0)
            label = tr(ability.label)
            label += "\n" + str(ability.get_cost(building)) + " " + tr("TR_AP")
            radial.set_field(icon, label, ability.index, self, "_ban_ability", [building, ability, radial])
            if building.is_ability_disabled(ability):
                radial.set_field_disabled(ability.index, "X", true)

func _ban_ability(args: Array) -> void:
    var building: BaseBuilding = args[0]
    var ability: Variant = args[1]
    var radial: Variant = args[2]

    building.set_ability_disabled(ability, not building.is_ability_disabled(ability))

    if building.is_ability_disabled(ability):
        radial.set_field_disabled(ability.index, "X", true)
    else:
        radial.clear_field_disabled(ability.index)
