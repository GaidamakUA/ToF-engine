class_name MapBuilder

const CLASS_GROUND: String = "ground"
const CLASS_FRAME: String = "frame"
const CLASS_DECORATION: String = "decoration"
const CLASS_TERRAIN: String = "terrain"
const SUB_CLASS_CONSTRUCTION: String = "construction"
const CLASS_BUILDING: String = "building"
const CLASS_UNIT: String = "unit"
const CLASS_DAMAGE: String = "damage"
const CLASS_HERO: String = "hero"

var map: Map

var editor: Variant = null
var enable_health: bool = false

func _init(map_scene: Map) -> void:
    self.map = map_scene


func place_ground(position: Vector2i, name: String, rotation: int) -> void:
    var tile: MapTile = self.map.model.get_tile(position)

    if tile.ground.is_present():
        self._notify_removal(tile.ground, position, self.map.builder.CLASS_GROUND)
        tile.ground.clear()

    var new_element: MapObject = self.place_element(position, name, rotation, 0, self.map.tiles_ground_anchor, tile.ground)
    if not self.map.settings.get_option("shadows"):
        self._disable_shadow(new_element)


func place_frame(position: Vector2i, name: String, rotation: int) -> void:
    var tile: MapTile = self.map.model.get_tile(position)

    if not tile.ground.is_present():
        return

    if tile.frame.is_present():
        self._notify_removal(tile.frame, position, self.map.builder.CLASS_FRAME)
        tile.frame.clear()

    var new_element: MapObject = self.place_element(position, name, rotation, self.map.GROUND_HEIGHT, self.map.tiles_frames_anchor, tile.frame)
    if not self.map.settings.get_option("shadows") or not self.map.settings.get_option("dec_shadows"):
        self._disable_shadow(new_element)

func place_decoration(position: Vector2i, name: String, rotation: int) -> void:
    var tile: MapTile = self.map.model.get_tile(position)

    if not tile.ground.is_present():
        return
    if tile.decoration.is_present():
        self._notify_removal(tile.decoration, position, self.map.builder.CLASS_DECORATION)
        tile.decoration.clear()
    if tile.damage.is_present():
        self._notify_removal(tile.damage, position, self.map.builder.CLASS_DAMAGE)
        tile.damage.clear()
    if tile.building.is_present():
        var building: BaseBuilding = tile.building.tile as BaseBuilding
        assert(building != null)
        self._notify_removal(tile.building, position, self.map.builder.CLASS_BUILDING, building.side, building._get_abilities_status())
        tile.building.clear()

    var new_element: MapObject = self.place_element(position, name, rotation, self.map.GROUND_HEIGHT, self.map.tiles_frames_anchor, tile.decoration)

    if tile.terrain.is_present() and (not new_element.can_share_space or not tile.terrain.tile.can_share_space):
        self._notify_removal(tile.terrain, position, self.map.builder.CLASS_TERRAIN)
        tile.terrain.clear()

    if not self.map.settings.get_option("shadows") or not self.map.settings.get_option("dec_shadows"):
        self._disable_shadow(new_element)

func place_damage(position: Vector2i, name: String, rotation: int) -> void:
    var tile: MapTile = self.map.model.get_tile(position)

    if not tile.ground.is_present():
        return
    if tile.decoration.is_present():
        self._notify_removal(tile.decoration, position, self.map.builder.CLASS_DECORATION)
        tile.decoration.clear()
    if tile.terrain.is_present():
        self._notify_removal(tile.terrain, position, self.map.builder.CLASS_TERRAIN)
        tile.terrain.clear()
    if tile.building.is_present():
        var building: BaseBuilding = tile.building.tile as BaseBuilding
        assert(building != null)
        self._notify_removal(tile.building, position, self.map.builder.CLASS_BUILDING, building.side, building._get_abilities_status())
        tile.building.clear()
    if tile.damage.is_present():
        self._notify_removal(tile.damage, position, self.map.builder.CLASS_DAMAGE)
        tile.damage.clear()

    var new_element: MapObject = self.place_element(position, name, rotation, self.map.GROUND_HEIGHT - 0.05, self.map.tiles_frames_anchor, tile.damage)
    self._disable_shadow(new_element)

func place_terrain(position: Vector2i, name: String, rotation: int) -> void:
    var tile: MapTile = self.map.model.get_tile(position)

    if not tile.ground.is_present():
        return
    if tile.unit.is_present():
        var unit: BaseUnit = tile.unit.tile as BaseUnit
        assert(unit != null)
        self._notify_removal(tile.unit, position, self.map.builder.CLASS_UNIT, unit.side)
        tile.unit.clear()
    if tile.terrain.is_present():
        self._notify_removal(tile.terrain, position, self.map.builder.CLASS_TERRAIN)
        tile.terrain.clear()
    if tile.building.is_present():
        var building: BaseBuilding = tile.building.tile as BaseBuilding
        assert(building != null)
        self._notify_removal(tile.building, position, self.map.builder.CLASS_BUILDING, building.side, building._get_abilities_status())
        tile.building.clear()
    if tile.damage.is_present():
        self._notify_removal(tile.damage, position, self.map.builder.CLASS_DAMAGE)
        tile.damage.clear()

    var new_element: MapObject = self.place_element(position, name, rotation, self.map.GROUND_HEIGHT, self.map.tiles_terrain_anchor, tile.terrain)

    if tile.decoration.is_present() and (not new_element.can_share_space or not tile.decoration.tile.can_share_space):
        self._notify_removal(tile.decoration, position, self.map.builder.CLASS_DECORATION)
        tile.decoration.clear()

    if not self.map.settings.get_option("shadows"):
        self._disable_shadow(new_element)

func place_building(position: Vector2i, name: String, rotation: int, side: Variant = null) -> void:
    var tile: MapTile = self.map.model.get_tile(position)

    if not tile.ground.is_present():
        return
    if tile.decoration.is_present():
        self._notify_removal(tile.decoration, position, self.map.builder.CLASS_DECORATION)
        tile.decoration.clear()
    if tile.unit.is_present():
        var unit: BaseUnit = tile.unit.tile as BaseUnit
        assert(unit != null)
        self._notify_removal(tile.unit, position, self.map.builder.CLASS_UNIT, unit.side)
        tile.unit.clear()
    if tile.terrain.is_present():
        self._notify_removal(tile.terrain, position, self.map.builder.CLASS_TERRAIN)
        tile.terrain.clear()
    if tile.building.is_present():
        var building: BaseBuilding = tile.building.tile as BaseBuilding
        assert(building != null)
        self._notify_removal(tile.building, position, self.map.builder.CLASS_BUILDING, building.side, building._get_abilities_status())
        tile.building.clear()
    if tile.damage.is_present():
        self._notify_removal(tile.damage, position, self.map.builder.CLASS_DAMAGE)
        tile.damage.clear()

    var new_element: BaseBuilding = self.place_element(position, name, rotation, self.map.GROUND_HEIGHT, self.map.tiles_buildings_anchor, tile.building) as BaseBuilding
    assert(new_element != null)
    if not self.map.settings.get_option("shadows"):
        self._disable_shadow(new_element)

    if side != null:
        self.set_building_side(position, str(side))

    new_element.disable_dlc_abilities(self.map.model.metadata["editor_version"])

func place_unit(position: Vector2i, name: String, rotation: int, side: Variant = null, ai_paused: bool = false) -> BaseUnit:
    var tile: MapTile = self.map.model.get_tile(position)

    if not tile.ground.is_present():
        return null

    return self.force_place_unit(position, name, rotation, side, ai_paused)

func force_place_unit(position: Vector2i, name: String, rotation: int, side: Variant = null, ai_paused: bool = false) -> BaseUnit:
    var tile: MapTile = self.map.model.get_tile(position)

    if tile.unit.is_present():
        var old_unit: BaseUnit = tile.unit.tile as BaseUnit
        assert(old_unit != null)
        self._notify_removal(tile.unit, position, self.map.builder.CLASS_UNIT, old_unit.side)
        tile.unit.clear()
    if tile.building.is_present():
        var building: BaseBuilding = tile.building.tile as BaseBuilding
        assert(building != null)
        self._notify_removal(tile.building, position, self.map.builder.CLASS_BUILDING, building.side, building._get_abilities_status())
        tile.building.clear()
    if tile.terrain.is_present() and not tile.can_acommodate_unit():
        self._notify_removal(tile.terrain, position, self.map.builder.CLASS_TERRAIN)
        tile.terrain.clear()


    var new_unit: BaseUnit = self.place_element(position, name, rotation, self.map.GROUND_HEIGHT, self.map.tiles_units_anchor, tile.unit) as BaseUnit
    assert(new_unit != null)
    if not self.map.settings.get_option("shadows"):
        self._disable_shadow(new_unit)

    if side != null:
        self.set_unit_side(position, str(side))
    else:
        self.set_unit_side(position, str(new_unit.side))
    new_unit.ai_paused = ai_paused
    new_unit.reset()

    if ai_paused:
        new_unit.remove_highlight()

    new_unit.disable_dlc_abilities(self.map.model.metadata["editor_version"])
    if self.enable_health and self.map.settings.get_option("show_health"):
        new_unit.enable_health()

    if self.map.model.metadata.has("allow_level_up"):
        new_unit.allow_level_up = self.map.model.metadata["allow_level_up"]

    return new_unit


func place_element(position: Vector2i, name: String, rotation: int, vertical_offset: float, anchor: Node3D, tile_fragment: TileFragment) -> MapObject:
    var new_tile: MapObject = self.map.templates.get_template(name)
    var world_position: Vector3 = self.map.map_to_local(position)

    anchor.add_child(new_tile)
    world_position.y = vertical_offset
    new_tile.set_position(world_position)
    new_tile.set_rotation(Vector3(0, deg_to_rad(rotation), 0))
    new_tile.current_rotation = rotation

    tile_fragment.set_tile(new_tile)

    return new_tile

func clear_tile_layer(position: Vector2i) -> void:
    var tile: MapTile = self.map.model.get_tile(position)

    if tile.unit.is_present():
        var unit: BaseUnit = tile.unit.tile as BaseUnit
        assert(unit != null)
        self._notify_removal(tile.unit, position, self.map.builder.CLASS_UNIT, unit.side, {}, false)
        tile.unit.clear()
    elif tile.building.is_present():
        var building: BaseBuilding = tile.building.tile as BaseBuilding
        assert(building != null)
        self._notify_removal(tile.building, position, self.map.builder.CLASS_BUILDING, building.side, building._get_abilities_status(), false)
        tile.building.clear()
    elif tile.terrain.is_present():
        self._notify_removal(tile.terrain, position, self.map.builder.CLASS_TERRAIN, null, {}, false)
        tile.terrain.clear()
    elif tile.decoration.is_present():
        self._notify_removal(tile.decoration, position, self.map.builder.CLASS_DECORATION, null, {}, false)
        tile.decoration.clear()
    elif tile.damage.is_present():
        self._notify_removal(tile.damage, position, self.map.builder.CLASS_DAMAGE, null, {}, false)
        tile.damage.clear()
    elif tile.frame.is_present():
        self._notify_removal(tile.frame, position, self.map.builder.CLASS_FRAME, null, {}, false)
        tile.frame.clear()
    elif tile.ground.is_present():
        self._notify_removal(tile.ground, position, self.map.builder.CLASS_GROUND, null, {}, false)
        tile.ground.clear()

func wipe_tile(position: Vector2i) -> void:
    var tile: MapTile = self.map.model.get_tile(position)

    tile.wipe()

func wipe_map() -> void:
    for tile_id: String in self.map.model.tiles.keys():
        self.map.model.tiles[tile_id].wipe()

func fill_map_from_data(data: Dictionary[String, Variant]) -> void:
    var tiles_data: Dictionary[String, Dictionary]
    tiles_data.assign(data["tiles"])
    var scripts: Dictionary[String, Dictionary] = {
        "stories" : {},
        "triggers" : {}
    }

    if data.has("scripts"):
        scripts.clear()
        scripts.assign(data["scripts"])

    if data.has("metadata"):
        var metadata: Dictionary[String, Variant]
        metadata.assign(data["metadata"])
        self.map.model.metadata = metadata

    self.attach_mouse_layer()

    for tile_id: String in self.map.model.tiles.keys():
        if tiles_data.has(tile_id):
            self.place_tile(tile_id, tiles_data[tile_id])

    self.map.model.ingest_scripts(scripts)

func attach_mouse_layer() -> void:
    var ground_point: BaseGround
    var tile: MapTile

    self.map.mouse_layer.initialize(self.map.model.SIZE, self.map.TILE_SIZE)
    if self.map.mouse_layer.mouse_layer.get_parent():
        self.map.mouse_layer.mouse_layer.get_parent().remove_child(self.map.mouse_layer.mouse_layer)
    self.map.tiles_ground_anchor.add_child(self.map.mouse_layer.mouse_layer)
    for key: String in self.map.mouse_layer.ground_points.keys():
        ground_point = self.map.mouse_layer.ground_points[key]
        tile = self.map.model.tiles[key]
        ground_point.bind_ground_for_mouse(self.map, tile.position)


func place_tile(tile_id: String, tile_data: Dictionary) -> void:
    var tile: MapTile = self.map.model.tiles[tile_id]
    var ground_data: Dictionary[String, Variant] = self._get_layer_data(tile_data, "ground")
    var frame_data: Dictionary[String, Variant] = self._get_layer_data(tile_data, "frame")
    var decoration_data: Dictionary[String, Variant] = self._get_layer_data(tile_data, "decoration")
    var terrain_data: Dictionary[String, Variant] = self._get_layer_data(tile_data, "terrain")
    var building_data: Dictionary[String, Variant] = self._get_layer_data(tile_data, "building")
    var unit_data: Dictionary[String, Variant] = self._get_layer_data(tile_data, "unit")

    if ground_data["tile"] != null:
        self.place_ground(tile.position, str(ground_data["tile"]), int(ground_data["rotation"]))

    if frame_data["tile"] != null:
        self.place_frame(tile.position, str(frame_data["tile"]), int(frame_data["rotation"]))

    if decoration_data["tile"] != null:
        self.place_decoration(tile.position, str(decoration_data["tile"]), int(decoration_data["rotation"]))

    if tile_data.has("damage"):
        var damage_data: Dictionary[String, Variant] = self._get_layer_data(tile_data, "damage")
        if damage_data["tile"] != null:
            self.place_damage(tile.position, str(damage_data["tile"]), int(damage_data["rotation"]))

    if terrain_data["tile"] != null:
        self.place_terrain(tile.position, str(terrain_data["tile"]), int(terrain_data["rotation"]))

    if building_data["tile"] != null:
        self.place_building(tile.position, str(building_data["tile"]), int(building_data["rotation"]), building_data["side"])
        if building_data.has("abilities"):
            var building: BaseBuilding = tile.building.tile as BaseBuilding
            assert(building != null)
            var abilities_status: Dictionary
            abilities_status.assign(building_data["abilities"])
            building.restore_abilities_status(abilities_status)

    if unit_data["tile"] != null:
        if not unit_data.has("ai_paused"):
            var raw_unit_data: Dictionary = tile_data["unit"]
            raw_unit_data["ai_paused"] = false
            unit_data["ai_paused"] = false
        self.place_unit(tile.position, str(unit_data["tile"]), int(unit_data["rotation"]), unit_data["side"], bool(unit_data["ai_paused"]))


func _get_layer_data(tile_data: Dictionary, layer: String) -> Dictionary[String, Variant]:
    var layer_data: Dictionary[String, Variant]
    layer_data.assign(tile_data[layer])
    return layer_data


func set_building_side(position: Vector2i, new_side: String, new_team: Variant = null) -> void:
    var tile: MapTile = self.map.model.get_tile(position)

    if tile.building.is_present():
        var building: BaseBuilding = tile.building.tile as BaseBuilding
        assert(building != null)
        building.set_side(new_side)
        building.set_team(new_team)
        building.set_side_material(self.map.templates.get_side_material(new_side))

func set_unit_side(position: Vector2i, new_side: String) -> void:
    var tile: MapTile = self.map.model.get_tile(position)
    if tile.unit.is_present():
        var unit: BaseUnit = tile.unit.tile as BaseUnit
        assert(unit != null)
        self._set_unit_side(unit, new_side)

func _set_unit_side(unit: BaseUnit, new_side: String) -> void:
    var material_type: String = self.map.templates.MATERIAL_NORMAL
    if unit.uses_metallic_material:
        material_type = self.map.templates.MATERIAL_METALLIC
    unit.set_side(new_side)
    unit.set_side_materials(self.map.templates.get_side_material(new_side, material_type), self.map.templates.get_side_material_desat(new_side, material_type))

func _notify_removal(tile_fragment: TileFragment, position: Vector2i, tile_class: String, side: Variant = null, modifiers: Dictionary = {}, double: bool = true) -> void:
    if self.editor != null:
        var removal_data: Dictionary[String, Variant] = {
            "type" : "remove",
            "class" : tile_class,
            "position" : position,
            "tile" : tile_fragment.tile.template_name,
            "rotation" : tile_fragment.tile.current_rotation,
            "side" : side,
            "modifiers" : modifiers,
            "double" : double
        }
        self.editor.notify_about_removal(removal_data)

func _disable_shadow(tile: MapObject) -> void:
    if tile.shadow_override and self.map.settings.get_option("shadows"):
        return

    tile.disable_shadow()

func rebuild_tile(tile_id: String, tile_data: Dictionary) -> void:
    var tile: MapTile = self.map.model.tiles[tile_id]
    tile.wipe()

    self.place_tile(tile_id, tile_data)
    tile.is_state_modified = true
    if tile.unit.is_present():
        var unit_data: Dictionary[String, Variant] = self._get_layer_data(tile_data, "unit")
        var unit: BaseUnit = tile.unit.tile as BaseUnit
        assert(unit != null)
        unit.restore_from_state(unit_data)
        if unit_data.has("passenger"):
            var passenger_data: Dictionary[String, Variant]
            passenger_data.assign(unit_data["passenger"])
            var passenger: BaseUnit = self.map.templates.get_template(str(passenger_data["tile"])) as BaseUnit
            assert(passenger != null)
            passenger.set_rotation(Vector3(0, deg_to_rad(int(passenger_data["rotation"])), 0))
            passenger.current_rotation = int(passenger_data["rotation"])
            if not self.map.settings.get_option("shadows"):
                self._disable_shadow(passenger)
            passenger.restore_from_state(passenger_data)
            self._set_unit_side(passenger, str(passenger_data["side"]))

            var carrier: Heli = unit as Heli
            assert(carrier != null)
            carrier.passenger = passenger
