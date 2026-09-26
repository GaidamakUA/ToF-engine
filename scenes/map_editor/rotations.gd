class_name MapEditorRotations

var rotations: Dictionary[String, PackedStringArray] = {}
var types: PackedStringArray = []
var players: PackedStringArray = []
var stored_state: Dictionary[String, String] = {}

func build_rotations(templates: MapTemplates, builder: MapBuilder) -> void:
    self.rotations[builder.CLASS_GROUND] = PackedStringArray(templates._ground_templates.keys())
    self.rotations[builder.CLASS_FRAME] = PackedStringArray(templates._frame_templates.keys())
    self.rotations[builder.CLASS_DECORATION] = PackedStringArray(templates._decoration_templates.keys() + templates._special_templates.keys())
    self.rotations[builder.CLASS_DAMAGE] = PackedStringArray(templates._damage_templates.keys())
    self.rotations[builder.SUB_CLASS_CONSTRUCTION] = PackedStringArray(templates._city_templates.keys() + templates._city_decoration_templates.keys() + templates._wall_templates.keys() + templates._railway_templates.keys())
    self.rotations[builder.CLASS_TERRAIN] = PackedStringArray(templates._nature_templates.keys())
    self.rotations[builder.CLASS_BUILDING] = PackedStringArray(templates._building_templates.keys())
    self.rotations[builder.CLASS_UNIT] = PackedStringArray(templates._unit_templates.keys())
    self.rotations[builder.CLASS_HERO] = PackedStringArray(templates._hero_templates.keys())
    self.types = PackedStringArray([
        builder.CLASS_GROUND,
        builder.CLASS_FRAME,
        builder.CLASS_DECORATION,
        builder.CLASS_DAMAGE,
        builder.CLASS_TERRAIN,
        builder.SUB_CLASS_CONSTRUCTION,
        builder.CLASS_BUILDING,
        builder.CLASS_UNIT,
        builder.CLASS_HERO,
    ])
    self.players = PackedStringArray(templates.side_materials.keys())


func get_map(name: String, type: String) -> Dictionary[String, String]:
    return self._get_neighbours(self.rotations[type], name)

func get_type_map(type: String) -> Dictionary[String, String]:
    return self._get_neighbours(self.types, type)

func get_player_map(player: String) -> Dictionary[String, String]:
    return self._get_neighbours(self.players, player)

func get_first_tile(type: String) -> String:
    if self.stored_state.has(type):
        return str(self.stored_state[type])

    return self.rotations[type][0]

func _get_neighbours(names: PackedStringArray, name: String) -> Dictionary[String, String]:
    var index: int = names.find(name)
    assert(index >= 0)
    return {
        "prev": names[wrapi(index - 1, 0, names.size())],
        "next": names[wrapi(index + 1, 0, names.size())],
    }

func store_state(type: String, tile: String) -> void:
    self.stored_state[type] = tile
