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
const UNIT_TILE_SCENE: PackedScene = preload("res://scenes/tiles/units/unit.tscn")

var _ground_templates: Dictionary[String, GroundTileResource] = {
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

var _damage_templates: Dictionary[String, PackedScene] = {
    self.DECO_GROUND_DMG_1 : preload("res://scenes/tiles/decorations/ground_damage_1.tscn"),
    self.DECO_GROUND_DMG_2 : preload("res://scenes/tiles/decorations/ground_damage_2.tscn"),
    "deco_ground_dmg3" : preload("res://scenes/tiles/decorations/ground_damage_3.tscn"),
    "deco_ground_dmg4" : preload("res://scenes/tiles/decorations/ground_damage_4.tscn"),
    self.DECO_GROUND_DMG_5 : preload("res://scenes/tiles/decorations/ground_damage_5.tscn"),
    self.DECO_GROUND_DMG_6 : preload("res://scenes/tiles/decorations/ground_damage_6.tscn"),
}

var _frame_templates: Dictionary[String, Variant] = {
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

var _decoration_templates: Dictionary[String, Variant] = {
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

var _railway_templates: Dictionary[String, Variant] = {
    "deco_rail_straight" : preload("res://resources/decoration/railway_straight.tres"),
    "deco_rail_straight2" : preload("res://resources/decoration/railway_straight2.tres"),
    "deco_rail_turn"     : preload("res://resources/decoration/railway_turn.tres"),
    "deco_rail_t"        : preload("res://resources/decoration/railway_t.tres"),
    "deco_rail_cross"    : preload("res://resources/decoration/railway_cross.tres"),
    "deco_rail_end"      : preload("res://resources/decoration/railway_end.tres"),
}

var _city_decoration_templates: Dictionary[String, Variant] = {
    "deco_fountain" : preload("res://resources/decoration/fountain_overtile.tres"),
    "deco_statue" : preload("res://resources/decoration/statue_overtile.tres"),
    "deco_statue_rat" : preload("res://resources/decoration/rat_statue_overtile.tres"),
    "deco_statue_capsule" : preload("res://resources/decoration/capsule_statue_overtile.tres"),
}

var _city_templates: Dictionary[String, Variant] = {
    "city_building_big1" : preload("res://scenes/tiles/city/building_big_1_overtile.tscn"),
    "city_building_big2" : preload("res://scenes/tiles/city/building_big_2_overtile.tscn"),
    "city_building_big3" : preload("res://scenes/tiles/city/building_big_3_overtile.tscn"),
    "city_building_big4" : preload("res://scenes/tiles/city/building_big_4_overtile.tscn"),
    "city_building_big5" : preload("res://scenes/tiles/city/building_big_5_overtile.tscn"),
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

var _damaged_city_templates: Dictionary[String, PackedScene] = {
    "damaged_statue" : preload("res://scenes/tiles/decorations/statue_damaged.tscn"),
    "damaged_statue_rat" : preload("res://scenes/tiles/decorations/rat_statue_damaged.tscn"),
    "damaged_statue_capsule" : preload("res://scenes/tiles/decorations/capsule_statue_damaged.tscn"),
    "damaged_fountain" : preload("res://scenes/tiles/decorations/fountain_damaged.tscn"),
    "damaged_building_medium1" : preload("res://scenes/tiles/city/building_medium_1_damaged.tscn"),
    "damaged_building_small1" : preload("res://scenes/tiles/city/building_small_1_damaged.tscn"),
    "damaged_building_small2" : preload("res://scenes/tiles/city/building_small_2_damaged.tscn"),
    "damaged_building_small3" : preload("res://scenes/tiles/city/building_small_3_damaged.tscn"),
    "damaged_building_small4" : preload("res://scenes/tiles/city/building_small_4_damaged.tscn"),
    "damaged_building_small5" : preload("res://scenes/tiles/city/building_small_5_damaged.tscn"),
    "damaged_building_small6" : preload("res://scenes/tiles/city/building_small_6_damaged.tscn"),
    "damaged_building_small10" : preload("res://scenes/tiles/city/building_small_10_damaged.tscn"),
    "damaged_building_small11" : preload("res://scenes/tiles/city/building_small_11_damaged.tscn"),
    "damaged_shop1" : preload("res://scenes/tiles/city/shop_1_damaged.tscn"),
    "damaged_shop2" : preload("res://scenes/tiles/city/shop_2_damaged.tscn"),
    "damaged_shop3" : preload("res://scenes/tiles/city/shop_3_damaged.tscn"),
    "damaged_farm1" : preload("res://scenes/tiles/city/farm_1_damaged.tscn"),
    "damaged_farm2" : preload("res://scenes/tiles/city/farm_2_damaged.tscn"),
    "damaged_building_big1" : preload("res://scenes/tiles/city/building_big_1_damaged.tscn"),
    "damaged_building_big2" : preload("res://scenes/tiles/city/building_big_2_damaged.tscn"),
    "damaged_building_big3" : preload("res://scenes/tiles/city/building_big_3_damaged.tscn"),
    "damaged_building_big4" : preload("res://scenes/tiles/city/building_big_4_damaged.tscn"),
    "damaged_building_big5" : preload("res://scenes/tiles/city/building_big_5_damaged.tscn"),

    "destroyed_statue" : preload("res://scenes/tiles/decorations/statue_destroyed.tscn"),
    "destroyed_statue_rat" : preload("res://scenes/tiles/decorations/rat_statue_destroyed.tscn"),
    "destroyed_statue_capsule" : preload("res://scenes/tiles/decorations/capsule_statue_destroyed.tscn"),
    "destroyed_fountain" : preload("res://scenes/tiles/decorations/fountain_destroyed.tscn"),
    "destroyed_building_medium1" : preload("res://scenes/tiles/city/building_medium_1_destroyed.tscn"),
    "destroyed_building_small1" : preload("res://scenes/tiles/city/building_small_1_destroyed.tscn"),
    "destroyed_building_small2" : preload("res://scenes/tiles/city/building_small_2_destroyed.tscn"),
    "destroyed_building_small3" : preload("res://scenes/tiles/city/building_small_3_destroyed.tscn"),
    "destroyed_building_small4" : preload("res://scenes/tiles/city/building_small_4_destroyed.tscn"),
    "destroyed_building_small5" : preload("res://scenes/tiles/city/building_small_5_destroyed.tscn"),
    "destroyed_building_small6" : preload("res://scenes/tiles/city/building_small_6_destroyed.tscn"),
    "destroyed_building_small10" : preload("res://scenes/tiles/city/building_small_10_destroyed.tscn"),
    "destroyed_building_small11" : preload("res://scenes/tiles/city/building_small_11_destroyed.tscn"),
    "destroyed_shop1" : preload("res://scenes/tiles/city/shop_1_destroyed.tscn"),
    "destroyed_shop2" : preload("res://scenes/tiles/city/shop_2_destroyed.tscn"),
    "destroyed_shop3" : preload("res://scenes/tiles/city/shop_3_destroyed.tscn"),
    "destroyed_farm1" : preload("res://scenes/tiles/city/farm_1_destroyed.tscn"),
    "destroyed_farm2" : preload("res://scenes/tiles/city/farm_2_destroyed.tscn"),
    "destroyed_building_big1" : preload("res://scenes/tiles/city/building_big_1_destroyed.tscn"),
    "destroyed_building_big2" : preload("res://scenes/tiles/city/building_big_2_destroyed.tscn"),
    "destroyed_building_big3" : preload("res://scenes/tiles/city/building_big_3_destroyed.tscn"),
    "destroyed_building_big4" : preload("res://scenes/tiles/city/building_big_4_destroyed.tscn"),
    "destroyed_building_big5" : preload("res://scenes/tiles/city/building_big_5_destroyed.tscn"),
}

var _wall_templates: Dictionary[String, Variant] = {
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

var _nature_templates: Dictionary[String, Variant] = {
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

var _special_templates: Dictionary[String, Variant] = {
    "special_key" : preload("res://scenes/tiles/special/key.tscn"),
    "deco_rail_stop" : preload("res://resources/decoration/railway_stop.tres"),
}

var _building_templates: Dictionary[String, PackedScene] = {
    self.MODERN_HQ : preload("res://scenes/tiles/buildings/blue/headquarters.tscn"),
    "modern_barracks" : preload("res://scenes/tiles/buildings/blue/barracks.tscn"),
    "modern_factory" : preload("res://scenes/tiles/buildings/blue/factory.tscn"),
    "modern_airfield" : preload("res://scenes/tiles/buildings/blue/airfield.tscn"),
    "modern_tower" : preload("res://scenes/tiles/buildings/blue/tower.tscn"),

    self.STEAMPUNK_HQ : preload("res://scenes/tiles/buildings/red/headquarters.tscn"),
    "steampunk_barracks" : preload("res://scenes/tiles/buildings/red/barracks.tscn"),
    "steampunk_factory" : preload("res://scenes/tiles/buildings/red/factory.tscn"),
    "steampunk_airfield" : preload("res://scenes/tiles/buildings/red/airfield.tscn"),
    "steampunk_tower" : preload("res://scenes/tiles/buildings/red/tower.tscn"),

    self.FUTURISTIC_HQ : preload("res://scenes/tiles/buildings/green/headquarters.tscn"),
    "futuristic_barracks" : preload("res://scenes/tiles/buildings/green/barracks.tscn"),
    "futuristic_factory" : preload("res://scenes/tiles/buildings/green/factory.tscn"),
    "futuristic_airfield" : preload("res://scenes/tiles/buildings/green/airfield.tscn"),
    "futuristic_tower" : preload("res://scenes/tiles/buildings/green/tower.tscn"),

    self.FEUDAL_HQ : preload("res://scenes/tiles/buildings/yellow/headquarters.tscn"),
    "feudal_barracks" : preload("res://scenes/tiles/buildings/yellow/barracks.tscn"),
    "feudal_factory" : preload("res://scenes/tiles/buildings/yellow/factory.tscn"),
    "feudal_airfield" : preload("res://scenes/tiles/buildings/yellow/airfield.tscn"),
    "feudal_tower" : preload("res://scenes/tiles/buildings/yellow/tower.tscn"),

    "neutral_lighthouse" : preload("res://scenes/tiles/buildings/neutral/lighthouse.tscn"),
}

var _unit_templates: Dictionary[String, Resource] = {
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

var _hero_templates: Dictionary[String, PackedScene] = {
    "npc_president" : preload("res://scenes/tiles/units/npc/president.tscn"),
    "hero_general" : preload("res://scenes/tiles/units/heroes/general.tscn"),
    "hero_commando" : preload("res://scenes/tiles/units/heroes/commando.tscn"),

    "npc_lord" : preload("res://scenes/tiles/units/npc/lord.tscn"),
    "hero_gentleman" : preload("res://scenes/tiles/units/heroes/gentleman.tscn"),
    "hero_noble" : preload("res://scenes/tiles/units/heroes/noble.tscn"),

    "npc_chancellor" : preload("res://scenes/tiles/units/npc/chancellor.tscn"),
    "hero_admiral" : preload("res://scenes/tiles/units/heroes/admiral.tscn"),
    "hero_captain" : preload("res://scenes/tiles/units/heroes/captain.tscn"),

    "npc_king" : preload("res://scenes/tiles/units/npc/king.tscn"),
    "hero_prince" : preload("res://scenes/tiles/units/heroes/prince.tscn"),
    "hero_warlord" : preload("res://scenes/tiles/units/heroes/warlord.tscn"),
}

var templates: Dictionary[String, Variant] = {}

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

var _other_templates: Dictionary[String, PackedScene] = {
    "dummy_ground" : preload("res://scenes/tiles/ground/mouse_listener_tile.tscn"),
}

var generic_building: Script = preload("res://scenes/tiles/buildings/building.gd")
var generic_unit: Script = preload("res://scenes/tiles/units/unit.gd")

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
    if template == null:
        return null

    if self.templates.size() == 0:
        _compile_templates_list()

    var template_entry: Variant = self.templates[template]
    var new_tile: MapObject
    var template_resource: Resource = template_entry as Resource
    var ground_tile_resource: GroundTileResource = template_entry as GroundTileResource
    if ground_tile_resource != null:
        var ground_tile: GroundTile = self.GROUND_TILE_SCENE.instantiate() as GroundTile
        ground_tile.configure(ground_tile_resource)
        new_tile = ground_tile
    elif template_resource is UnitResource:
        var unit: BaseUnit = self.UNIT_TILE_SCENE.instantiate() as BaseUnit
        unit.configure(template_resource as UnitResource)
        new_tile = unit
    else:
        new_tile = (template_entry as PackedScene).instantiate()
    new_tile.template_name = template

    return new_tile

func get_side_material(side: String, _type:="normal") -> Resource:
    #if type == self.MATERIAL_METALLIC:
    #    return self.side_materials_metallic[side]

    return self.side_materials[side]

func get_side_material_desat(side: String, _type:="normal") -> Resource:
    #if type == self.MATERIAL_METALLIC:
    #    return self.side_materials_metallic_desat[side]

    return self.side_materials_desat[side]
