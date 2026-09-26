class_name MapTemplates

const GROUND_GRASS := "ground_grass"

const DECO_GROUND_DMG_1 := "deco_ground_dmg1"
const DECO_GROUND_DMG_2 := "deco_ground_dmg2"
const DECO_GROUND_DMG_5 := "deco_ground_dmg5"
const DECO_GROUND_DMG_6 := "deco_ground_dmg6"

const MODERN_HQ := "modern_hq"

const STEAMPUNK_HQ := "steampunk_hq"

const FUTURISTIC_HQ := "futuristic_hq"

const FEUDAL_HQ := "feudal_hq"

const PLAYER_NEUTRAL := "neutral"
const PLAYER_BLUE := "blue"
const PLAYER_RED := "red"
const PLAYER_GREEN := "green"
const PLAYER_YELLOW := "yellow"
const PLAYER_BLACK := "black"

const MATERIAL_NORMAL := "normal"
const MATERIAL_METALLIC := "metallic"
const GROUND_TILE_SCENE: PackedScene = preload("res://scenes/tiles/ground/ground_tile.tscn")
const DAMAGE_TILE_SCENE: PackedScene = preload("res://scenes/tiles/damaged_tile.tscn")
const ROTATING_TILE_SCENE: PackedScene = preload("res://scenes/tiles/special/key.tscn")
const MOUSE_LISTENER_TILE_SCENE: PackedScene = preload("res://scenes/tiles/ground/mouse_listener_tile.tscn")
const BUILDING_TILE_SCENE: PackedScene = preload("res://scenes/tiles/buildings/building.tscn")
const UNIT_TILE_SCENE: PackedScene = preload("res://scenes/tiles/units/unit.tscn")
const HERO_TILE_SCENE: PackedScene = preload("res://scenes/tiles/units/heroes/hero.tscn")
const NPC_TILE_SCENE: PackedScene = preload("res://scenes/tiles/units/npc/npc.tscn")

var _ground_templates: Dictionary[String, TileResource] = {
    self.GROUND_GRASS : preload("res://resources/ground/ground_grass.tres"),
    "ground_concrete" : preload("res://resources/ground/ground_concrete.tres"),
    "ground_mud" : preload("res://resources/ground/ground_mud.tres"),
    "ground_river1" : preload("res://resources/ground/ground_river1.tres"),
    "ground_river2" : preload("res://resources/ground/ground_river2.tres"),
    "ground_swamp" : preload("res://resources/ground/ground_swamp.tres"),
    "ground_swamp2" : preload("res://resources/ground/ground_swamp2.tres"),
    "ground_swamp3" : preload("res://resources/ground/ground_swamp3.tres"),
    "ground_road1" : preload("res://resources/ground/ground_road1.tres"),
    "ground_road2" : preload("res://resources/ground/ground_road2.tres"),
    "ground_road3" : preload("res://resources/ground/ground_road3.tres"),
    "ground_road4" : preload("res://resources/ground/ground_road4.tres"),
    "ground_road_transition" : preload("res://resources/ground/ground_road_transition.tres"),
    "ground_road_transition2" : preload("res://resources/ground/ground_road_transition2.tres"),
    "ground_road_transition3" : preload("res://resources/ground/ground_road_transition3.tres"),
    "ground_road_transition4" : preload("res://resources/ground/ground_road_transition4.tres"),
    "ground_dirt_road1" : preload("res://resources/ground/ground_dirt_road1.tres"),
    "ground_dirt_road2" : preload("res://resources/ground/ground_dirt_road2.tres"),
    "ground_dirt_road3" : preload("res://resources/ground/ground_dirt_road3.tres"),
    "ground_dirt_road4" : preload("res://resources/ground/ground_dirt_road4.tres"),
    "ground_snow" : preload("res://resources/ground/ground_snow.tres"),
    "ground_snow_river1" : preload("res://resources/ground/ground_snow_river1.tres"),
    "ground_snow_river2" : preload("res://resources/ground/ground_snow_river2.tres"),
    "ground_snow_road1" : preload("res://resources/ground/ground_snow_road1.tres"),
    "ground_snow_road2" : preload("res://resources/ground/ground_snow_road2.tres"),
    "ground_snow_road3" : preload("res://resources/ground/ground_snow_road3.tres"),
    "ground_snow_road4" : preload("res://resources/ground/ground_snow_road4.tres"),
    "ground_snow_road_transition" : preload("res://resources/ground/ground_snow_road_transition.tres"),
    "ground_snow_road_transition2" : preload("res://resources/ground/ground_snow_road_transition2.tres"),
    "ground_snow_road_transition3" : preload("res://resources/ground/ground_snow_road_transition3.tres"),
    "ground_snow_road_transition4" : preload("res://resources/ground/ground_snow_road_transition4.tres"),
    "ground_snow_dirt_road1" : preload("res://resources/ground/ground_snow_dirt_road1.tres"),
    "ground_snow_dirt_road2" : preload("res://resources/ground/ground_snow_dirt_road2.tres"),
    "ground_snow_dirt_road3" : preload("res://resources/ground/ground_snow_dirt_road3.tres"),
    "ground_snow_dirt_road4" : preload("res://resources/ground/ground_snow_dirt_road4.tres"),
    "ground_sand" : preload("res://resources/ground/ground_sand.tres"),
    "ground_sand_river1" : preload("res://resources/ground/ground_sand_river1.tres"),
    "ground_sand_river2" : preload("res://resources/ground/ground_sand_river2.tres"),
    "ground_sand_road1" : preload("res://resources/ground/ground_sand_road1.tres"),
    "ground_sand_road2" : preload("res://resources/ground/ground_sand_road2.tres"),
    "ground_sand_road3" : preload("res://resources/ground/ground_sand_road3.tres"),
    "ground_sand_road4" : preload("res://resources/ground/ground_sand_road4.tres"),
    "ground_sand_road_transition" : preload("res://resources/ground/ground_sand_road_transition.tres"),
    "ground_sand_road_transition2" : preload("res://resources/ground/ground_sand_road_transition2.tres"),
    "ground_sand_road_transition3" : preload("res://resources/ground/ground_sand_road_transition3.tres"),
    "ground_sand_road_transition4" : preload("res://resources/ground/ground_sand_road_transition4.tres"),
    "ground_sand_dirt_road1" : preload("res://resources/ground/ground_sand_dirt_road1.tres"),
    "ground_sand_dirt_road2" : preload("res://resources/ground/ground_sand_dirt_road2.tres"),
    "ground_sand_dirt_road3" : preload("res://resources/ground/ground_sand_dirt_road3.tres"),
    "ground_sand_dirt_road4" : preload("res://resources/ground/ground_sand_dirt_road4.tres"),
    "bridge_plate" : preload("res://resources/ground/bridge_plate.tres"),
    "bridge2_plate" : preload("res://resources/ground/bridge2_plate.tres"),
    "bridge_legs" : preload("res://resources/ground/bridge_legs.tres"),
    "bridge2_legs" : preload("res://resources/ground/bridge2_legs.tres"),
    "bridge_stone" : preload("res://resources/ground/bridge_stone.tres"),
    "bridge2_stone" : preload("res://resources/ground/bridge2_stone.tres"),
    "ground_flyable" : preload("res://resources/ground/ground_flyable.tres"),
}

var _damage_templates: Dictionary[String, TileResource] = {
    self.DECO_GROUND_DMG_1 : preload("res://resources/damage/ground_hole_1.tres"),
    self.DECO_GROUND_DMG_2 : preload("res://resources/damage/ground_hole_2.tres"),
    "deco_ground_dmg3" : preload("res://resources/damage/ground_hole_3.tres"),
    "deco_ground_dmg4" : preload("res://resources/damage/ground_hole_4.tres"),
    self.DECO_GROUND_DMG_5 : preload("res://resources/damage/ground_hole_5.tres"),
    self.DECO_GROUND_DMG_6 : preload("res://resources/damage/ground_hole_6.tres"),
}

var _frame_templates: Dictionary[String, TileResource] = {
    "frame_grass1" : preload("res://resources/frame/grass_1_overtile.tres"),
    "frame_grass2" : preload("res://resources/frame/grass_2_overtile.tres"),
    "frame_grass3" : preload("res://resources/frame/grass_3_overtile.tres"),
    "frame_grass4" : preload("res://resources/frame/grass_4_overtile.tres"),
    "frame_grass5" : preload("res://resources/frame/grass_5_overtile.tres"),
    "frame_grass6" : preload("res://resources/frame/grass_6_overtile.tres"),
    "frame_wheat" : preload("res://resources/frame/wheat_overtile.tres"),
    "frame_river1" : preload("res://resources/frame/river_plants_1_overtile.tres"),
    "frame_river2" : preload("res://resources/frame/river_plants_2_overtile.tres"),
    "frame_river3" : preload("res://resources/frame/river_plants_3_overtile.tres"),
    "frame_river4" : preload("res://resources/frame/river_plants_4_overtile.tres"),
    "frame_river5" : preload("res://resources/frame/river_plants_5_overtile.tres"),
    "frame_river6" : preload("res://resources/frame/river_plants_6_overtile.tres"),
    "frame_road1" : preload("res://resources/frame/road_1_overtile.tres"),
    "frame_road2" : preload("res://resources/frame/road_2_overtile.tres"),
    "frame_road3" : preload("res://resources/frame/road_3_overtile.tres"),
    "frame_road4" : preload("res://resources/frame/road_4_overtile.tres"),

    "frame_snow2" : preload("res://resources/frame/snow_2_overtile.tres"),
    "frame_snow3" : preload("res://resources/frame/snow_3_overtile.tres"),
    "frame_snow4" : preload("res://resources/frame/snow_4_overtile.tres"),
    "frame_snow_river1" : preload("res://resources/frame/river_snow_1_overtile.tres"),
    "frame_snow_river2" : preload("res://resources/frame/river_snow_2_overtile.tres"),
    "frame_snow_river3" : preload("res://resources/frame/river_snow_3_overtile.tres"),
    "frame_snow_river4" : preload("res://resources/frame/river_snow_4_overtile.tres"),

    "frame_sand_beach1" : preload("res://resources/frame/beach_1_overtile.tres"),
    "frame_sand_beach2" : preload("res://resources/frame/beach_2_overtile.tres"),
    "frame_sand_beach3" : preload("res://resources/frame/beach_3_overtile.tres"),

    "frame_mud1" : preload("res://resources/frame/mud_1_overtile.tres"),
    "frame_mud2" : preload("res://resources/frame/mud_2_overtile.tres"),

    "frame_fence" : preload("res://resources/frame/wired_fence_overtile.tres"),
    "frame_laser" : preload("res://resources/frame/laser_fence_overtile.tres"),
    "frame_wall" : preload("res://resources/frame/wall_fence_overtile.tres"),
}

var _decoration_templates: Dictionary[String, TileResource] = {
    "deco_flower1" : preload("res://resources/decoration/flowers_1_overtile.tres"),
    "deco_flower2" : preload("res://resources/decoration/flowers_2_overtile.tres"),
    "deco_flower3" : preload("res://resources/decoration/flowers_3_overtile.tres"),
    "deco_flower4" : preload("res://resources/decoration/flowers_4_overtile.tres"),
    "deco_flower5" : preload("res://resources/decoration/flowers_5_overtile.tres"),
    "deco_flower6" : preload("res://resources/decoration/flowers_6_overtile.tres"),
    "deco_flower7" : preload("res://resources/decoration/flowers_7_overtile.tres"),
    "deco_flower8" : preload("res://resources/decoration/flowers_8_overtile.tres"),
    "deco_flower9" : preload("res://resources/decoration/flowers_9_overtile.tres"),
    "deco_flower10" : preload("res://resources/decoration/flowers_10_overtile.tres"),
    "deco_flower11" : preload("res://resources/decoration/flowers_11_overtile.tres"),
    "deco_flower12" : preload("res://resources/decoration/flowers_12_overtile.tres"),
    "deco_log" : preload("res://resources/decoration/log_1_overtile.tres"),
    "deco_rocks1" : preload("res://resources/decoration/rocks_1_overtile.tres"),
    "deco_rocks2" : preload("res://resources/decoration/rocks_2_overtile.tres"),

    "deco_stumps1" : preload("res://resources/decoration/stumps_1_overtile.tres"),
    "deco_stumps2" : preload("res://resources/decoration/stumps_2_overtile.tres"),
    "deco_stumps3" : preload("res://resources/decoration/stumps_3_overtile.tres"),
    "deco_stumps4" : preload("res://resources/decoration/stumps_4_overtile.tres"),

    "deco_beach1" : preload("res://resources/decoration/beach_1_overtile.tres"),
    "deco_beach2" : preload("res://resources/decoration/beach_2_overtile.tres"),
    "deco_beach3" : preload("res://resources/decoration/beach_3_overtile.tres"),
}

var _railway_templates: Dictionary[String, TileResource] = {
    "deco_rail_straight" : preload("res://resources/decoration/railway_straight.tres"),
    "deco_rail_straight2" : preload("res://resources/decoration/railway_straight2.tres"),
    "deco_rail_turn"     : preload("res://resources/decoration/railway_turn.tres"),
    "deco_rail_t"        : preload("res://resources/decoration/railway_t.tres"),
    "deco_rail_cross"    : preload("res://resources/decoration/railway_cross.tres"),
    "deco_rail_end"      : preload("res://resources/decoration/railway_end.tres"),
}

var _city_decoration_templates: Dictionary[String, TileResource] = {
    "deco_fountain" : preload("res://resources/decoration/fountain_overtile.tres"),
    "deco_statue" : preload("res://resources/decoration/statue_overtile.tres"),
    "deco_statue_rat" : preload("res://resources/decoration/rat_statue_overtile.tres"),
    "deco_statue_capsule" : preload("res://resources/decoration/capsule_statue_overtile.tres"),
}

var _city_templates: Dictionary[String, TileResource] = {
    "city_building_big1" : preload("res://resources/terrain/building_big_1_overtile.tres"),
    "city_building_big2" : preload("res://resources/terrain/building_big_2_overtile.tres"),
    "city_building_big3" : preload("res://resources/terrain/building_big_3_overtile.tres"),
    "city_building_big4" : preload("res://resources/terrain/building_big_4_overtile.tres"),
    "city_building_big5" : preload("res://resources/terrain/building_big_5_overtile.tres"),
    "city_building_small5" : preload("res://resources/terrain/building_small_5_overtile.tres"),
    "city_building_small6" : preload("res://resources/terrain/building_small_6_overtile.tres"),
    "city_building_medium1" : preload("res://resources/terrain/building_medium_1_overtile.tres"),
    "city_building_small1" : preload("res://resources/terrain/building_small_1_overtile.tres"),
    "city_building_small2" : preload("res://resources/terrain/building_small_2_overtile.tres"),
    "city_building_small3" : preload("res://resources/terrain/building_small_3_overtile.tres"),
    "city_building_small4" : preload("res://resources/terrain/building_small_4_overtile.tres"),
    "city_building_small10" : preload("res://resources/terrain/building_small_10_overtile.tres"),
    "city_building_small11" : preload("res://resources/terrain/building_small_11_overtile.tres"),
    "city_farm1" : preload("res://resources/terrain/farm_1_overtile.tres"),
    "city_farm2" : preload("res://resources/terrain/farm_2_overtile.tres"),
    "city_shop1" : preload("res://resources/terrain/shop_1_overtile.tres"),
    "city_shop2" : preload("res://resources/terrain/shop_2_overtile.tres"),
    "city_shop3" : preload("res://resources/terrain/shop_3_overtile.tres"),
    "city_bridge" : preload("res://resources/terrain/river_bridge_overtile.tres"),
    "city_bridge_wood" : preload("res://resources/terrain/wooden_bridge_overtile.tres"),
    "city_roadblock" : preload("res://resources/terrain/roadblock_overtile.tres"),
    "city_sandbags" : preload("res://resources/terrain/sandbags_overtile.tres"),
    "bridge_suspension" : preload("res://resources/terrain/bridge_suspension.tres"),
    "bridge_suspension_tiled" : preload("res://resources/terrain/bridge_suspension_tiled.tres"),
    "bridge_stone_barrier" : preload("res://resources/terrain/bridge_stone_barrier.tres"),
    "bridge_stone_barrier_tiled" : preload("res://resources/terrain/bridge_stone_barrier_tiled.tres"),
}

var _damaged_city_templates: Dictionary[String, DamageTileResource] = {
    "damaged_statue" : preload("res://resources/terrain/statue_damaged.tres"),
    "damaged_statue_rat" : preload("res://resources/terrain/rat_statue_damaged.tres"),
    "damaged_statue_capsule" : preload("res://resources/terrain/capsule_statue_damaged.tres"),
    "damaged_fountain" : preload("res://resources/terrain/fountain_damaged.tres"),
    "damaged_building_medium1" : preload("res://resources/terrain/building_medium_1_damaged.tres"),
    "damaged_building_small1" : preload("res://resources/terrain/building_small_1_damaged.tres"),
    "damaged_building_small2" : preload("res://resources/terrain/building_small_2_damaged.tres"),
    "damaged_building_small3" : preload("res://resources/terrain/building_small_3_damaged.tres"),
    "damaged_building_small4" : preload("res://resources/terrain/building_small_4_damaged.tres"),
    "damaged_building_small5" : preload("res://resources/terrain/building_small_5_damaged.tres"),
    "damaged_building_small6" : preload("res://resources/terrain/building_small_6_damaged.tres"),
    "damaged_building_small10" : preload("res://resources/terrain/building_small_10_damaged.tres"),
    "damaged_building_small11" : preload("res://resources/terrain/building_small_11_damaged.tres"),
    "damaged_shop1" : preload("res://resources/terrain/shop_1_damaged.tres"),
    "damaged_shop2" : preload("res://resources/terrain/shop_2_damaged.tres"),
    "damaged_shop3" : preload("res://resources/terrain/shop_3_damaged.tres"),
    "damaged_farm1" : preload("res://resources/terrain/farm_1_damaged.tres"),
    "damaged_farm2" : preload("res://resources/terrain/farm_2_damaged.tres"),
    "damaged_building_big1" : preload("res://resources/terrain/building_big_1_damaged.tres"),
    "damaged_building_big2" : preload("res://resources/terrain/building_big_2_damaged.tres"),
    "damaged_building_big3" : preload("res://resources/terrain/building_big_3_damaged.tres"),
    "damaged_building_big4" : preload("res://resources/terrain/building_big_4_damaged.tres"),
    "damaged_building_big5" : preload("res://resources/terrain/building_big_5_damaged.tres"),

    "destroyed_statue" : preload("res://resources/terrain/statue_destroyed.tres"),
    "destroyed_statue_rat" : preload("res://resources/terrain/rat_statue_destroyed.tres"),
    "destroyed_statue_capsule" : preload("res://resources/terrain/capsule_statue_destroyed.tres"),
    "destroyed_fountain" : preload("res://resources/terrain/fountain_destroyed.tres"),
    "destroyed_building_medium1" : preload("res://resources/terrain/building_medium_1_destroyed.tres"),
    "destroyed_building_small1" : preload("res://resources/terrain/building_small_1_destroyed.tres"),
    "destroyed_building_small2" : preload("res://resources/terrain/building_small_2_destroyed.tres"),
    "destroyed_building_small3" : preload("res://resources/terrain/building_small_3_destroyed.tres"),
    "destroyed_building_small4" : preload("res://resources/terrain/building_small_4_destroyed.tres"),
    "destroyed_building_small5" : preload("res://resources/terrain/building_small_5_destroyed.tres"),
    "destroyed_building_small6" : preload("res://resources/terrain/building_small_6_destroyed.tres"),
    "destroyed_building_small10" : preload("res://resources/terrain/building_small_10_destroyed.tres"),
    "destroyed_building_small11" : preload("res://resources/terrain/building_small_11_destroyed.tres"),
    "destroyed_shop1" : preload("res://resources/terrain/shop_1_destroyed.tres"),
    "destroyed_shop2" : preload("res://resources/terrain/shop_2_destroyed.tres"),
    "destroyed_shop3" : preload("res://resources/terrain/shop_3_destroyed.tres"),
    "destroyed_farm1" : preload("res://resources/terrain/farm_1_destroyed.tres"),
    "destroyed_farm2" : preload("res://resources/terrain/farm_2_destroyed.tres"),
    "destroyed_building_big1" : preload("res://resources/terrain/building_big_1_destroyed.tres"),
    "destroyed_building_big2" : preload("res://resources/terrain/building_big_2_destroyed.tres"),
    "destroyed_building_big3" : preload("res://resources/terrain/building_big_3_destroyed.tres"),
    "destroyed_building_big4" : preload("res://resources/terrain/building_big_4_destroyed.tres"),
    "destroyed_building_big5" : preload("res://resources/terrain/building_big_5_destroyed.tres"),
}

var _wall_templates: Dictionary[String, TileResource] = {
    "castle_wall_straight" : preload("res://resources/terrain/wall_straight.tres"),
    "castle_wall_straight2" : preload("res://resources/terrain/wall_straight2.tres"),
    "castle_wall_corner" : preload("res://resources/terrain/wall_corner.tres"),
    "castle_wall_cross" : preload("res://resources/terrain/wall_cross.tres"),
    "castle_wall_t" : preload("res://resources/terrain/wall_t.tres"),
    "castle_wall_t2" : preload("res://resources/terrain/wall_t2.tres"),
    "castle_wall_gate" : preload("res://resources/terrain/wall_gate.tres"),
    "castle_wall_gate_closed" : preload("res://resources/terrain/wall_gate_closed.tres"),

    "brick_wall_straight" : preload("res://resources/terrain/wall2_straight.tres"),
    "brick_wall_straight2" : preload("res://resources/terrain/wall2_straight2.tres"),
    "brick_wall_corner" : preload("res://resources/terrain/wall2_corner.tres"),
    "brick_wall_cross" : preload("res://resources/terrain/wall2_cross.tres"),
    "brick_wall_t" : preload("res://resources/terrain/wall2_t.tres"),
    "brick_wall_t2" : preload("res://resources/terrain/wall2_t2.tres"),
    "brick_wall_gate" : preload("res://resources/terrain/wall2_gate.tres"),
    "brick_wall_gate_closed" : preload("res://resources/terrain/wall2_gate_closed.tres"),

    "fence_wall_straight" : preload("res://resources/terrain/wall3_straight.tres"),
    "fence_wall_straight2" : preload("res://resources/terrain/wall3_straight2.tres"),
    "fence_wall_corner" : preload("res://resources/terrain/wall3_corner.tres"),
    "fence_wall_cross" : preload("res://resources/terrain/wall3_cross.tres"),
    "fence_wall_t" : preload("res://resources/terrain/wall3_t.tres"),
    "fence_wall_t2" : preload("res://resources/terrain/wall3_t2.tres"),
    "fence_wall_gate" : preload("res://resources/terrain/wall3_gate.tres"),
    "fence_wall_gate_closed" : preload("res://resources/terrain/wall3_gate_closed.tres"),

    "futuristic_wall_straight" : preload("res://resources/terrain/wall4_straight.tres"),
    "futuristic_wall_straight2" : preload("res://resources/terrain/wall4_straight2.tres"),
    "futuristic_wall_corner" : preload("res://resources/terrain/wall4_corner.tres"),
    "futuristic_wall_cross" : preload("res://resources/terrain/wall4_cross.tres"),
    "futuristic_wall_t" : preload("res://resources/terrain/wall4_t.tres"),
    "futuristic_wall_t2" : preload("res://resources/terrain/wall4_t2.tres"),
    "futuristic_wall_gate" : preload("res://resources/terrain/wall4_gate.tres"),
    "futuristic_wall_gate_closed" : preload("res://resources/terrain/wall4_gate_closed.tres"),
}

var _nature_templates: Dictionary[String, TileResource] = {
    "nature_big_rocks1" : preload("res://resources/terrain/big_rocks_1_overtile.tres"),
    "nature_big_rocks2" : preload("res://resources/terrain/big_rocks_2_overtile.tres"),
    "nature_big_rocks3" : preload("res://resources/terrain/big_rocks_3_overtile.tres"),
    "nature_big_rocks4" : preload("res://resources/terrain/big_rocks_4_overtile.tres"),
    "nature_trees1" : preload("res://resources/terrain/trees_1_overtile.tres"),
    "nature_trees2" : preload("res://resources/terrain/trees_2_overtile.tres"),
    "nature_trees3" : preload("res://resources/terrain/trees_3_overtile.tres"),
    "nature_trees10" : preload("res://resources/terrain/trees_10_overtile.tres"),
    "nature_trees11" : preload("res://resources/terrain/trees_11_overtile.tres"),
    "nature_trees4" : preload("res://resources/terrain/trees_4_overtile.tres"),
    "nature_trees5" : preload("res://resources/terrain/trees_5_overtile.tres"),
    "nature_trees6" : preload("res://resources/terrain/trees_6_overtile.tres"),
    "nature_trees12" : preload("res://resources/terrain/trees_12_overtile.tres"),
    "nature_trees13" : preload("res://resources/terrain/trees_13_overtile.tres"),
    "nature_trees7" : preload("res://resources/terrain/trees_7_overtile.tres"),
    "nature_trees8" : preload("res://resources/terrain/trees_8_overtile.tres"),
    "nature_trees9" : preload("res://resources/terrain/trees_9_overtile.tres"),
    "nature_trees14" : preload("res://resources/terrain/trees_14_overtile.tres"),
    "nature_trees15" : preload("res://resources/terrain/trees_15_overtile.tres"),
    "nature_trees16" : preload("res://resources/terrain/trees_16_overtile.tres"),
    "nature_trees17" : preload("res://resources/terrain/trees_17_overtile.tres"),
    "nature_trees18" : preload("res://resources/terrain/trees_18_overtile.tres"),

    "nature_sand_cacti1" : preload("res://resources/terrain/cacti_1_overtile.tres"),
    "nature_sand_cacti2" : preload("res://resources/terrain/cacti_2_overtile.tres"),
    "nature_sand_cacti3" : preload("res://resources/terrain/cacti_3_overtile.tres"),
    "nature_sand_dunes1" : preload("res://resources/terrain/dunes_1_overtile.tres"),
    "nature_sand_dunes2" : preload("res://resources/terrain/dunes_2_overtile.tres"),
    "nature_sand_dunes3" : preload("res://resources/terrain/dunes_3_overtile.tres"),
    "nature_sand_dunes4" : preload("res://resources/terrain/dunes_4_overtile.tres"),
    "nature_sand_palms1" : preload("res://resources/terrain/palms_1_overtile.tres"),
    "nature_sand_palms2" : preload("res://resources/terrain/palms_2_overtile.tres"),
    "nature_sand_palms3" : preload("res://resources/terrain/palms_3_overtile.tres"),
    "nature_sand_palms4" : preload("res://resources/terrain/palms_4_overtile.tres"),
}

var _special_templates: Dictionary[String, TileResource] = {
    "special_key" : preload("res://resources/decoration/key.tres"),
    "deco_rail_stop" : preload("res://resources/decoration/railway_stop.tres"),
}

var _building_templates: Dictionary[String, BuildingResource] = {
    self.MODERN_HQ : preload("res://resources/buildings/blue/headquarters.tres"),
    "modern_barracks" : preload("res://resources/buildings/blue/barracks.tres"),
    "modern_factory" : preload("res://resources/buildings/blue/factory.tres"),
    "modern_airfield" : preload("res://resources/buildings/blue/airfield.tres"),
    "modern_tower" : preload("res://resources/buildings/blue/tower.tres"),

    self.STEAMPUNK_HQ : preload("res://resources/buildings/red/headquarters.tres"),
    "steampunk_barracks" : preload("res://resources/buildings/red/barracks.tres"),
    "steampunk_factory" : preload("res://resources/buildings/red/factory.tres"),
    "steampunk_airfield" : preload("res://resources/buildings/red/airfield.tres"),
    "steampunk_tower" : preload("res://resources/buildings/red/tower.tres"),

    self.FUTURISTIC_HQ : preload("res://resources/buildings/green/headquarters.tres"),
    "futuristic_barracks" : preload("res://resources/buildings/green/barracks.tres"),
    "futuristic_factory" : preload("res://resources/buildings/green/factory.tres"),
    "futuristic_airfield" : preload("res://resources/buildings/green/airfield.tres"),
    "futuristic_tower" : preload("res://resources/buildings/green/tower.tres"),

    self.FEUDAL_HQ : preload("res://resources/buildings/yellow/headquarters.tres"),
    "feudal_barracks" : preload("res://resources/buildings/yellow/barracks.tres"),
    "feudal_factory" : preload("res://resources/buildings/yellow/factory.tres"),
    "feudal_airfield" : preload("res://resources/buildings/yellow/airfield.tres"),
    "feudal_tower" : preload("res://resources/buildings/yellow/tower.tres"),

    "neutral_lighthouse" : preload("res://resources/buildings/neutral/lighthouse.tres"),
}

var _unit_templates: Dictionary[String, UnitResource] = {
    "blue_infantry" : preload("res://resources/units/blue/infantry.tres"),
    "blue_tank" : preload("res://resources/units/blue/tank.tres"),
    "blue_heli" : preload("res://resources/units/blue/heli.tres"),
    "blue_m_inf" : preload("res://resources/units/blue/mobile_infantry.tres"),
    "blue_rocket" : preload("res://resources/units/blue/rocket_artillery.tres"),
    "blue_scout" : preload("res://resources/units/blue/scout_heli.tres"),
    "blue_truck" : preload("res://resources/units/blue/truck.tres"),

    "red_infantry" : preload("res://resources/units/red/infantry.tres"),
    "red_tank" : preload("res://resources/units/red/tank.tres"),
    "red_heli" : preload("res://resources/units/red/heli.tres"),
    "red_m_inf" : preload("res://resources/units/red/mobile_infantry.tres"),
    "red_rocket" : preload("res://resources/units/red/rocket_artillery.tres"),
    "red_scout" : preload("res://resources/units/red/scout_heli.tres"),
    "red_truck" : preload("res://resources/units/red/truck.tres"),

    "green_infantry" : preload("res://resources/units/green/infantry.tres"),
    "green_tank" : preload("res://resources/units/green/tank.tres"),
    "green_heli" : preload("res://resources/units/green/heli.tres"),
    "green_m_inf" : preload("res://resources/units/green/mobile_infantry.tres"),
    "green_rocket" : preload("res://resources/units/green/rocket_artillery.tres"),
    "green_scout" : preload("res://resources/units/green/scout_heli.tres"),
    "green_truck" : preload("res://resources/units/green/truck.tres"),

    "yellow_infantry" : preload("res://resources/units/yellow/infantry.tres"),
    "yellow_tank" : preload("res://resources/units/yellow/tank.tres"),
    "yellow_heli" : preload("res://resources/units/yellow/heli.tres"),
    "yellow_m_inf" : preload("res://resources/units/yellow/mobile_infantry.tres"),
    "yellow_rocket" : preload("res://resources/units/yellow/rocket_artillery.tres"),
    "yellow_scout" : preload("res://resources/units/yellow/scout_heli.tres"),
    "yellow_truck" : preload("res://resources/units/yellow/truck.tres"),
}

var _hero_templates: Dictionary[String, UnitResource] = {
    "npc_president" : preload("res://resources/units/npc/president.tres"),
    "hero_general" : preload("res://resources/units/heroes/general.tres"),
    "hero_commando" : preload("res://resources/units/heroes/commando.tres"),

    "npc_lord" : preload("res://resources/units/npc/lord.tres"),
    "hero_gentleman" : preload("res://resources/units/heroes/gentleman.tres"),
    "hero_noble" : preload("res://resources/units/heroes/noble.tres"),

    "npc_chancellor" : preload("res://resources/units/npc/chancellor.tres"),
    "hero_admiral" : preload("res://resources/units/heroes/admiral.tres"),
    "hero_captain" : preload("res://resources/units/heroes/captain.tres"),

    "npc_king" : preload("res://resources/units/npc/king.tres"),
    "hero_prince" : preload("res://resources/units/heroes/prince.tres"),
    "hero_warlord" : preload("res://resources/units/heroes/warlord.tres"),
}

var templates: Dictionary[String, MapObjectResource] = {}

var side_materials: Dictionary[String, Resource] = {
    self.PLAYER_NEUTRAL : ResourceLoader.load("res://assets/materials/arne32_neutral.tres"),
    self.PLAYER_BLUE : ResourceLoader.load("res://assets/materials/arne32_blue.tres"),
    self.PLAYER_RED : ResourceLoader.load("res://assets/materials/arne32_red.tres"),
    self.PLAYER_GREEN : ResourceLoader.load("res://assets/materials/arne32_green.tres"),
    self.PLAYER_YELLOW : ResourceLoader.load("res://assets/materials/arne32_yellow.tres"),
    self.PLAYER_BLACK : ResourceLoader.load("res://assets/materials/arne32_black.tres"),
}
var side_materials_desat: Dictionary[String, Resource] = {
    self.PLAYER_NEUTRAL : ResourceLoader.load("res://assets/materials/arne32_neutral.tres"),
    self.PLAYER_BLUE : ResourceLoader.load("res://assets/materials/arne32_blue_desat.tres"),
    self.PLAYER_RED : ResourceLoader.load("res://assets/materials/arne32_red_desat.tres"),
    self.PLAYER_GREEN : ResourceLoader.load("res://assets/materials/arne32_green_desat.tres"),
    self.PLAYER_YELLOW : ResourceLoader.load("res://assets/materials/arne32_yellow_desat.tres"),
    self.PLAYER_BLACK : ResourceLoader.load("res://assets/materials/arne32_black_desat.tres"),
}

var side_materials_metallic: Dictionary[String, Resource] = {
    self.PLAYER_NEUTRAL : ResourceLoader.load("res://assets/materials/arne32_metallic_neutral.tres"),
    self.PLAYER_BLUE : ResourceLoader.load("res://assets/materials/arne32_metallic_blue.tres"),
    self.PLAYER_RED : ResourceLoader.load("res://assets/materials/arne32_metallic_red.tres"),
    self.PLAYER_GREEN : ResourceLoader.load("res://assets/materials/arne32_metallic_green.tres"),
    self.PLAYER_YELLOW : ResourceLoader.load("res://assets/materials/arne32_metallic_yellow.tres"),
    self.PLAYER_BLACK : ResourceLoader.load("res://assets/materials/arne32_metallic_black.tres"),
}
var side_materials_metallic_desat: Dictionary[String, Resource] = {
    self.PLAYER_NEUTRAL : ResourceLoader.load("res://assets/materials/arne32_metallic_neutral.tres"),
    self.PLAYER_BLUE : ResourceLoader.load("res://assets/materials/arne32_metallic_blue_desat.tres"),
    self.PLAYER_RED : ResourceLoader.load("res://assets/materials/arne32_metallic_red_desat.tres"),
    self.PLAYER_GREEN : ResourceLoader.load("res://assets/materials/arne32_metallic_green_desat.tres"),
    self.PLAYER_YELLOW : ResourceLoader.load("res://assets/materials/arne32_metallic_yellow_desat.tres"),
    self.PLAYER_BLACK : ResourceLoader.load("res://assets/materials/arne32_metallic_black_desat.tres"),
}

var _other_templates: Dictionary[String, MapObjectResource] = {
    "dummy_ground" : preload("res://resources/ground/mouse_listener.tres"),
}

func _compile_templates_list() -> void:
    var partial_templates: Array[Dictionary] = [
        self._ground_templates,
        self._damage_templates,
        self._frame_templates,
        self._decoration_templates,
        self._railway_templates,
        self._city_decoration_templates,
        self._city_templates,
        self._damaged_city_templates,
        self._wall_templates,
        self._nature_templates,
        self._special_templates,
        self._building_templates,
        self._unit_templates,
        self._hero_templates,
        self._other_templates
    ]
    for partial_dict: Dictionary in partial_templates:
        for template_key: String in partial_dict:
            self.templates[template_key] = partial_dict[template_key]

func get_template(template: String) -> MapObject:
    var template_entry: MapObjectResource = self.get_template_source(template)
    if template_entry == null:
        return null
    var new_tile: MapObject
    var damage_tile_resource: DamageTileResource = template_entry as DamageTileResource
    var tile_resource: TileResource = template_entry as TileResource
    var unit_resource: UnitResource = template_entry as UnitResource
    if template_entry is MouseListenerTileResource:
        new_tile = self.MOUSE_LISTENER_TILE_SCENE.instantiate() as MapObject
    elif template_entry is RotatingTileResource:
        var rotating_tile: GroundTile = self.ROTATING_TILE_SCENE.instantiate() as GroundTile
        rotating_tile.configure(tile_resource)
        new_tile = rotating_tile
    elif damage_tile_resource != null:
        var damage_tile: DamagedTile = self.DAMAGE_TILE_SCENE.instantiate() as DamagedTile
        damage_tile.configure(damage_tile_resource)
        new_tile = damage_tile
    elif tile_resource != null:
        var ground_tile: GroundTile = self.GROUND_TILE_SCENE.instantiate() as GroundTile
        ground_tile.configure(tile_resource)
        new_tile = ground_tile
    elif template_entry is BuildingResource:
        var building: BaseBuilding = self.BUILDING_TILE_SCENE.instantiate() as BaseBuilding
        building.configure(template_entry as BuildingResource)
        new_tile = building
    elif unit_resource != null:
        var unit_scene: PackedScene = self.UNIT_TILE_SCENE
        if unit_resource.kind == UnitResource.Kind.HERO:
            unit_scene = self.HERO_TILE_SCENE
        elif unit_resource.kind == UnitResource.Kind.NPC:
            unit_scene = self.NPC_TILE_SCENE
        var unit: BaseUnit = unit_scene.instantiate() as BaseUnit
        unit.configure(unit_resource)
        new_tile = unit
    assert(new_tile != null, template)
    new_tile.template_name = template

    return new_tile

func get_template_source(template: String) -> MapObjectResource:
    if template == null:
        return null

    if self.templates.size() == 0:
        _compile_templates_list()

    return self.templates[template]

func get_side_material(side: String, _type:="normal") -> Resource:
    #if type == self.MATERIAL_METALLIC:
    #    return self.side_materials_metallic[side]

    return self.side_materials[side]

func get_side_material_desat(side: String, _type:="normal") -> Resource:
    #if type == self.MATERIAL_METALLIC:
    #    return self.side_materials_metallic_desat[side]

    return self.side_materials_desat[side]
