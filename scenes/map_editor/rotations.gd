
class_name MapEditorRotations

var rotations: Dictionary[String, Dictionary] = {}
var types: Dictionary[String, Dictionary] = {}
var players: Dictionary[String, Dictionary] = {}
var stored_state: Dictionary[String, String] = {}

func build_rotations(templates: MapTemplates, builder: MapBuilder) -> void:
    self.rotations[builder.CLASS_GROUND] = self.build_from_array(templates._ground_templates.keys())

    self.rotations[builder.CLASS_FRAME] = self.build_from_array(templates._frame_templates.keys())

    self.rotations[builder.CLASS_DECORATION] = self.build_from_array(templates._decoration_templates.keys() + templates._special_templates.keys())

    self.rotations[builder.CLASS_DAMAGE] = self.build_from_array(templates._damage_templates.keys())

    self.rotations[builder.SUB_CLASS_CONSTRUCTION] = self.build_from_array(templates._city_templates.keys() + templates._city_decoration_templates.keys() + templates._wall_templates.keys() + templates._railway_templates.keys())

    self.rotations[builder.CLASS_TERRAIN] = self.build_from_array(templates._nature_templates.keys())

    self.rotations[builder.CLASS_BUILDING] = self.build_from_array(templates._building_templates.keys())

    self.rotations[builder.CLASS_UNIT] = self.build_from_array(templates._unit_templates.keys())

    self.rotations[builder.CLASS_HERO] = self.build_from_array(templates._hero_templates.keys())

    self.types = self.build_from_array([
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

    self.players = self.build_from_array(templates.side_materials.keys())


func get_map(name: String, type: String) -> Dictionary[String, String]:
    var map: Dictionary[String, String]
    map.assign(self.rotations[type][name])
    return map

func get_type_map(type: String) -> Dictionary[String, String]:
    var map: Dictionary[String, String]
    map.assign(self.types[type])
    return map

func get_player_map(player: String) -> Dictionary[String, String]:
    var map: Dictionary[String, String]
    map.assign(self.players[player])
    return map

func get_first_tile(type: String) -> String:
    if self.stored_state.has(type):
        return str(self.stored_state[type])

    return str(self.rotations[type].keys()[0])

func build_from_array(names: Array) -> Dictionary[String, Dictionary]:
    var rotation_map: Dictionary[String, Dictionary] = {}

    for i: int in range(names.size()):
        if i == 0:
            rotation_map[str(names[i])] = {
                "prev" : str(names[names.size()-1]),
                "next" : str(names[i+1]),
            }
        elif i + 1 == names.size():
            rotation_map[str(names[i])] = {
                "prev" : str(names[i-1]),
                "next" : str(names[0]),
            }
        else:
            rotation_map[str(names[i])] = {
                "prev" : str(names[i-1]),
                "next" : str(names[i+1]),
            }

    return rotation_map

func store_state(type: String, tile: String) -> void:
    self.stored_state[type] = tile
