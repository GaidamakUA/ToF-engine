class_name Collateral

const COLLATERAL_CHANCE: float = 0.5

var board: Board
var model: BoardModel

func _init(model_object: BoardModel) -> void:
    self.model = model_object
    self.board = model_object.board

func apply_destroyed_unit_collateral(tile: MapTile) -> void:
    self.generate_collateral(tile)
    self.damage_tile(tile)


func damage_tile(tile: MapTile) -> Variant:
    if tile == null or not tile.ground.is_present():
        return null
    var ground: BaseTile = tile.ground.tile
    if ground == null:
        return null
    if tile.damage.is_present() or tile.terrain.is_present() or ground.unit_can_fly:
        return null

    var angles: Array[int] = [0, 90, 180, 270]
    var damage_templates: Array[String] = [
        self.model.map_templates.DECO_GROUND_DMG_1,
        self.model.map_templates.DECO_GROUND_DMG_2,
        self.model.map_templates.DECO_GROUND_DMG_5,
        self.model.map_templates.DECO_GROUND_DMG_6,
    ]

    if tile.decoration.is_present():
        tile.decoration.clear()

    var random_angle: int = angles[randi() % angles.size()]
    var random_template: String = damage_templates[randi() % damage_templates.size()]
    apply_tile_damage(tile.position, random_template, random_angle)
    var damaged_tiles: Array[Vector2i] = [tile.position]
    self.model.events.emit_collateral_damage_applied(tile.position, damaged_tiles, random_template)

    return [tile.position, random_template, random_angle]

func apply_tile_damage(tile_position: Vector2i, template: String, angle: int) -> void:
    var tile: MapTile = self.model.get_tile_at(tile_position)
    if tile == null:
        return

    if self.board != null and self.board.map != null:
        self.board.map.builder.place_damage(tile_position, template, angle)
        self.board.map.model.get_tile(tile_position).is_state_modified = true
        return

    var damaged_tile := self.model.map_templates.get_template(template) as BaseTile
    if damaged_tile == null:
        return
    damaged_tile.current_rotation = angle
    tile.damage.set_tile(damaged_tile)
    tile.is_state_modified = true

func generate_collateral(tile: MapTile) -> Array[Vector2i]:
    var summary: Array[Vector2i] = []

    for neighbour: MapTile in tile.neighbours.values():
        if randf() <= self.COLLATERAL_CHANCE:
            if self.damage_terrain(neighbour):
                summary.append(neighbour.position)

    if summary.size() > 0:
        self.model.events.emit_collateral_damage_applied(tile.position, summary, null)

    return summary

func damage_terrain(tile: MapTile) -> bool:
    if not tile.terrain.is_present():
        return false

    var terrain: BaseTile = tile.terrain.tile
    if not terrain.is_damageable():
        return false

    var next_damage_stage_template: String = terrain.next_damage_stage_template
    var rotation_y: int = terrain.current_rotation
    if rotation_y == 0:
        rotation_y = int(terrain.get_rotation_degrees().y)

    tile.terrain.clear()
    if self.board != null and self.board.map != null:
        self.board.map.builder.place_terrain(tile.position, next_damage_stage_template, rotation_y)
    else:
        var damaged_terrain := self.model.map_templates.get_template(next_damage_stage_template) as BaseTile
        if damaged_terrain == null:
            return false
        damaged_terrain.current_rotation = rotation_y
        tile.terrain.set_tile(damaged_terrain)
    if tile.terrain.tile != null and tile.terrain.tile.has_method(&"show_explosion"):
        tile.terrain.tile.show_explosion()
    tile.is_state_modified = true

    return true
