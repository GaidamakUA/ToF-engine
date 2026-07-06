class_name Collateral

const COLLATERAL_CHANCE: float = 0.5

var board: Board
var model: BoardModel

func _init(model_object: BoardModel) -> void:
    self.model = model_object
    self.board = model_object.board

func damage_tile(tile: MapTile) -> Variant:
    var ground: BaseTile = tile.ground.tile
    if tile.damage.is_present() or tile.terrain.is_present() or ground.unit_can_fly:
        return null

    var angles: Array[int] = [0, 90, 180, 270]
    var damage_templates: Array[String] = [
        self.board.map.templates.DECO_GROUND_DMG_1,
        self.board.map.templates.DECO_GROUND_DMG_2,
        self.board.map.templates.DECO_GROUND_DMG_5,
        self.board.map.templates.DECO_GROUND_DMG_6,
    ]

    if tile.decoration.is_present():
        tile.decoration.clear()

    var random_angle: int = angles[randi() % angles.size()]
    var random_template: String = damage_templates[randi() % damage_templates.size()]
    apply_tile_damage(tile.position, random_template, random_angle)

    return [tile.position, random_template, random_angle]

func apply_tile_damage(tile_position: Vector2i, template: String, angle: int) -> void:
    self.board.map.builder.place_damage(tile_position, template, angle)
    self.board.map.model.get_tile(tile_position).is_state_modified = true

func generate_collateral(tile: MapTile) -> Array[Vector2i]:
    var summary: Array[Vector2i] = []

    for neighbour: MapTile in tile.neighbours.values():
        if randf() <= self.COLLATERAL_CHANCE:
            if self.damage_terrain(neighbour):
                summary.append(neighbour.position)

    return summary

func damage_terrain(tile: MapTile) -> bool:
    if not tile.terrain.is_present():
        return false

    var terrain: BaseTile = tile.terrain.tile
    if not terrain.is_damageable():
        return false

    var next_damage_stage_template: String = terrain.next_damage_stage_template
    var rotation: Vector3 = terrain.get_rotation_degrees()

    tile.terrain.clear()
    self.board.map.builder.place_terrain(tile.position, next_damage_stage_template, int(rotation.y))
    tile.terrain.tile.show_explosion()
    tile.is_state_modified = true

    return true
