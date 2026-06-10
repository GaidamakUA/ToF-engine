class_name MapModel
const SIZE: int = 40

var tiles: Dictionary[String, MapTile] = {}
var scripts: Dictionary[String, Dictionary] = {
    "stories" : {},
    "triggers" : {}
}
var metadata: Dictionary = {}

func _init() -> void:
    for x in range(self.SIZE):
        for y in range(self.SIZE):
            self.tiles[str(x) + "_" + str(y)] = MapTile.new(x, y)
    self.connect_neightbours()

func wipe_metadata() -> void:
    self.metadata.clear()

func wipe_scripts() -> void:
    self.scripts["stories"].clear()
    self.scripts["triggers"].clear()

func get_tile(position: Vector2i) -> MapTile:
    var key: String = str(position.x) + "_" + str(position.y)
    if self.tiles.has(key):
        return self.tiles[key]
    return null

func get_tile2(x: int, y: int) -> MapTile:
    # Dirty solution
    return self.tiles[str(x) + "_" + str(y)]

func get_dict() -> Dictionary[String, Variant]:
    var tiles_dict: Dictionary[String, Dictionary] = {}
    for key: String in self.tiles.keys():
        if self.tiles[key].has_content():
            tiles_dict[key] = self.tiles[key].get_dict()

    return {
        "metadata" : self.metadata,
        "tiles" : tiles_dict,
        "scripts" : self.scripts
    }

func connect_neightbours() -> void:
    var tile: MapTile

    for x: int in range(self.SIZE):
        for y: int in range(self.SIZE):

            tile = self.get_tile2(x, y)

            if x > 0:
                tile.add_neighbour(tile.WEST, self.get_tile2(x-1, y))

            if x < self.SIZE - 1:
                tile.add_neighbour(tile.EAST, self.get_tile2(x+1, y))

            if y > 0:
                tile.add_neighbour(tile.NORTH, self.get_tile2(x, y-1))

            if y < self.SIZE - 1:
                tile.add_neighbour(tile.SOUTH, self.get_tile2(x, y+1))


func get_player_units(side: String) -> Array[BaseUnit]:
    var units: Array[BaseUnit] = []
    for key: String in self.tiles.keys():
        if self.tiles[key].has_friendly_unit(side):
            units.append(self.tiles[key].unit.get_map_object())

    return units

func get_all_units_tiles() -> Array[MapTile]:
    var units_tiles: Array[MapTile] = []
    for key: String in self.tiles.keys():
        if self.tiles[key].unit.is_present():
            units_tiles.append(self.tiles[key])

    return units_tiles


func get_player_buildings(side: String) -> Array[BaseBuilding]:
    var buildings: Array[BaseBuilding] = []
    for key: String in self.tiles.keys():
        if self.tiles[key].has_friendly_building(side):
            buildings.append(self.tiles[key].building.get_map_object())

    return buildings

func get_player_units_tiles(side: String) -> Array[MapTile]:
    var units: Array[MapTile] = []
    for key: String in self.tiles.keys():
        if self.tiles[key].has_friendly_unit(side):
            units.append(self.tiles[key])

    return units

func get_player_buildings_tiles(side: String) -> Array[MapTile]:
    var buildings: Array[MapTile] = []
    for key: String in self.tiles.keys():
        if self.tiles[key].has_friendly_building(side):
            buildings.append(self.tiles[key])

    return buildings

func get_enemy_units_tiles(side: String, team: Variant = null) -> Array[MapTile]:
    var units: Array[MapTile] = []
    for key: String in self.tiles.keys():
        if self.tiles[key].has_enemy_unit(side, team):
            units.append(self.tiles[key])

    return units

func get_enemy_buildings_tiles(side: String, team: Variant = null) -> Array[MapTile]:
    var buildings: Array[MapTile] = []
    for key: String in self.tiles.keys():
        if self.tiles[key].has_enemy_building(side, team):
            buildings.append(self.tiles[key])

    return buildings

func ingest_scripts(incoming_scripts: Variant) -> void:
    if incoming_scripts == null or incoming_scripts.is_empty():
        return

    self.scripts.assign(incoming_scripts)

func get_player_bunker_position(side: String) -> Variant:
    for key: String in self.tiles.keys():
        if self.tiles[key].has_friendly_hq(side):
            return self.tiles[key].position

    return null

func get_player_bunkers(side: String) -> Array[MapTile]:
    var bunkers: Array[MapTile] = []

    for key: String in self.tiles.keys():
        if self.tiles[key].has_friendly_hq(side):
            bunkers.append(self.tiles[key])

    return bunkers

func get_player_hero_position(side: String) -> Variant:
    for key: String in self.tiles.keys():
        if self.tiles[key].has_friendly_hero(side):
            return self.tiles[key].position

    return null

func get_player_heroes(side: String) -> Array[HeroUnit]:
    var heroes: Array[HeroUnit] = []

    for key: String in self.tiles.keys():
        if self.tiles[key].has_friendly_hero(side):
            heroes.append(self.tiles[key].unit.get_map_object())

    return heroes

func get_unit_position(unit: BaseUnit) -> Variant:
    if unit == null:
        return null

    for key: String in self.tiles.keys():
        if self.tiles[key].unit.get_map_object() == unit:
            return [self.tiles[key].position.x, self.tiles[key].position.y]

    return null

func wipe_all_units() -> void:
    for key: String in self.tiles.keys():
        if self.tiles[key].unit.is_present():
            self.tiles[key].unit.clear()
