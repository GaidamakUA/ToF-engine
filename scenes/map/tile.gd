class_name MapTile
var settings: Variant

const EAST := "e"
const WEST := "w"
const NORTH := "n"
const SOUTH := "s"

var position := Vector2i(0, 0)

var ground := TileSlot.new()
var frame := TileSlot.new()
var decoration := TileSlot.new()
var terrain := TileSlot.new()
var building := TileSlot.new()
var unit := TileSlot.new()
var damage := TileSlot.new()

var fragments: Array[TileSlot] = []

var neighbours: Dictionary[String, MapTile] = {}

var is_state_modified := false

func _init(x: int, y: int) -> void:
    self.position.x = x
    self.position.y = y

    self.fragments = [
        self.ground,
        self.frame,
        self.decoration,
        self.terrain,
        self.building,
        self.unit,
        self.damage,
    ]

func has_content() -> bool:
    return fragments.any(func(f: TileSlot) -> bool: return f.is_present())

func get_dict() -> Dictionary[String, Variant]:
    return {
        "ground" : self.ground.get_dict(),
        "frame" : self.frame.get_dict(),
        "decoration" : self.decoration.get_dict(),
        "terrain" : self.terrain.get_dict(),
        "building" : self.building.get_dict(),
        "unit" : self.unit.get_dict(),
        "damage" : self.damage.get_dict(),
    }

func wipe() -> void:
    self.fragments.map(func(f: TileSlot) -> void: f.clear())

func is_selectable(side: String) -> bool:
    if self.unit.is_present():
        return self._get_unit().side == side
    elif self.building.is_present():
        return self._get_building().side == side

    return false

func _get_unit() -> BaseUnit:
    var typed_unit: BaseUnit = self.unit.get_map_object() as BaseUnit
    assert(typed_unit != null)
    return typed_unit

func _get_building() -> BaseBuilding:
    var typed_building: BaseBuilding = self.building.get_map_object() as BaseBuilding
    assert(typed_building != null)
    return typed_building

func add_neighbour(direction: String, tile: MapTile) -> void:
    self.neighbours[direction] = tile

func get_neighbour(direction: String) -> MapTile:
    if self.neighbours.has(direction):
        return self.neighbours[direction]

    return null

func is_neighbour(tile: MapTile) -> bool:
    for direction: String in self.neighbours.keys():
        if self.neighbours[direction] == tile:
            return true
    return false


func can_acommodate_unit(moving_unit: BaseUnit = null) -> bool:
    if not self.ground.is_present():
        return false
    if self.ground.get_map_object().unit_can_fly and (moving_unit == null or not moving_unit.can_fly):
        return false
    if self.unit.is_present():
        return false
    if self.building.is_present():
        return false
    if self.terrain.is_present():
        return self.terrain.get_map_object().unit_can_stand

    return true

func can_pass_through(moving_unit: BaseUnit) -> bool:
    if not self.ground.is_present():
        return false
    if self.ground.get_map_object().unit_can_fly and not moving_unit.can_fly:
        return false
    if self.building.is_present() and not moving_unit.can_fly:
        return false
    if self.has_enemy_unit(moving_unit.side, moving_unit.team):
        return false
    if self.terrain.is_present() and not moving_unit.can_fly:
        return self.terrain.get_map_object().unit_can_stand

    return true

func has_enemy_unit(side: String, team: Variant = null) -> bool:
    if self.unit.is_present():
        var typed_unit: BaseUnit = self._get_unit()
        if typed_unit.side != side:
            if team != null:
                return typed_unit.team != team
            return true
    return false

func has_allied_unit(team: Variant) -> bool:
    if self.unit.is_present():
        if team != null:
            return self._get_unit().team == team
    return false

func has_friendly_unit(side: String) -> bool:
    if self.unit.is_present() && self._get_unit().side == side:
        return true
    return false

func has_enemy_building(side: String, team: Variant = null) -> bool:
    if self.building.is_present():
        var typed_building: BaseBuilding = self._get_building()
        if typed_building.side != side:
            if team != null:
                return typed_building.team != team
            return true
    return false

func has_allied_building(team: Variant) -> bool:
    if self.building.is_present():
        if team != null:
            return self._get_building().team == team
    return false

func has_friendly_building(side: String) -> bool:
    if self.building.is_present() && self._get_building().side == side:
        return true
    return false

func neighbours_enemy_unit(side: String, team: Variant = null) -> bool:
    for direction: String in self.neighbours.keys():
        if self.neighbours[direction].has_enemy_unit(side, team):
            return true
    return false

func can_attack_neightbour_enemy_unit(attacking_unit: BaseUnit) -> bool:
    for direction: String in self.neighbours.keys():
        if self.neighbours[direction].has_enemy_unit(attacking_unit.side, attacking_unit.team):
            if attacking_unit.can_attack(self.neighbours[direction]._get_unit()):
                return true
    return false

func neighbours_enemy_building(side: String, team: Variant = null) -> bool:
    for direction: String in self.neighbours.keys():
        if self.neighbours[direction].has_enemy_building(side, team):
            return true
    return false

func get_direction_to_neighbour(tile: MapTile) -> Variant:
    for direction: String in self.neighbours.keys():
        if self.neighbours[direction] == tile:
            return direction
    return null

func can_unit_interact(interacting_unit: BaseUnit) -> bool:
    if not interacting_unit.has_moves():
        return false

    if self.has_enemy_unit(interacting_unit.side, interacting_unit.team) && interacting_unit.can_attack(self._get_unit()) && interacting_unit.has_attacks():
        return true

    if self.has_enemy_building(interacting_unit.side, interacting_unit.team) && interacting_unit.can_capture:
        return true

    return false

func has_friendly_hq(side: String) -> bool:
    if self.building.is_present():
        var typed_building: BaseBuilding = self._get_building()
        if typed_building.side == side && typed_building.template_name in ["modern_hq", "steampunk_hq", "futuristic_hq", "feudal_hq"]:
            return true
    return false

func has_friendly_hero(side: String) -> bool:
    if self.has_friendly_unit(side) && self._get_unit().unit_class == "hero":
        return true
    return false

func is_ground_damage_possible() -> bool:
    if not self.ground.is_present():
        return false
    if self.unit.is_present():
        return false
    if self.building.is_present():
        return false
    if self.terrain.is_present():
        return false
    if self.damage.is_present():
        return false

    return true

func is_object_damage_possible() -> bool:
    return self.terrain.is_present() and self.terrain.get_map_object().is_damageable()

func is_damageable() -> bool:
    return self.is_ground_damage_possible() or self.is_object_damage_possible()

func apply_invisibility() -> void:
    for fragment: TileSlot in self.fragments:
        if fragment.is_present() and fragment.get_map_object().is_invisible:
            fragment.get_map_object().hide_mesh()


func _settings_changed(key: String, _new_value: Variant) -> void:
    var shadows: bool = self.settings.get_option("shadows")
    var dec_shadows: bool = self.settings.get_option("dec_shadows")

    if key == "shadows" or key == "dec_shadows":
        if shadows:
            if self.ground.is_present():
                self.ground.get_map_object().enable_shadow()

            if self.terrain.is_present():
                self.terrain.get_map_object().enable_shadow()

            if self.building.is_present():
                self.building.get_map_object().enable_shadow()

            if self.unit.is_present():
                self.unit.get_map_object().enable_shadow()

            if dec_shadows:
                if self.frame.is_present():
                    self.frame.get_map_object().enable_shadow()
                if self.decoration.is_present():
                    self.decoration.get_map_object().enable_shadow()
            else:
                if self.frame.is_present():
                    _disable_shadow(self.frame.get_map_object(), shadows)
                if self.decoration.is_present():
                    _disable_shadow(self.decoration.get_map_object(), shadows)
        else:
            if self.ground.is_present():
                _disable_shadow(self.ground.get_map_object(), shadows)
            if self.frame.is_present():
                _disable_shadow(self.frame.get_map_object(), shadows)
            if self.decoration.is_present():
                _disable_shadow(self.decoration.get_map_object(), shadows)
            if self.terrain.is_present():
                _disable_shadow(self.terrain.get_map_object(), shadows)
            if self.building.is_present():
                _disable_shadow(self.building.get_map_object(), shadows)
            if self.unit.is_present():
                _disable_shadow(self.unit.get_map_object(), shadows)
    if key == "show_health":
        if _new_value:
            if self.unit.is_present():
                self.unit.get_map_object().show_health()
        else:
            if self.unit.is_present():
                self.unit.get_map_object().hide_health()

func _disable_shadow(tile: MapObject, shadow_setting: bool) -> void:
    if tile.shadow_override and shadow_setting:
        return

    tile.disable_shadow()
