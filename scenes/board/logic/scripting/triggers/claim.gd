extends BaseTrigger
class_name ClaimTrigger

var amount: int = 1
var list: Array[Array] = []
var player_id: Variant = null
var player_side: Variant = null

func _init() -> void:
    self.observed_event_type = BuildingCapturedEvent

func _observe(_event: BaseEvent) -> void:
    var event: BuildingCapturedEvent = _event as BuildingCapturedEvent
    if self._is_watched_building(event.building):
        var side: Variant = event.new_side

        if self.player_id != null:
            side = self.board.state.get_player_side_by_id(self.player_id)
        if self.player_side != null:
            side = self.player_side

        if self._count_buildings_for_side(side) >= self.amount:
            self.execute_outcome(event)


func _get_outcome_metadata(_event: BaseEvent) -> Dictionary[String, Variant]:
    var event: BuildingCapturedEvent = _event as BuildingCapturedEvent
    return {
        'building' : event.building,
        'new_side' : event.new_side,
        'old_side' : event.old_side
    }


func ingest_details(details: Dictionary[String, Variant]) -> void:
    self.list = []
    list.assign(details['list'])
    if details.has('player'):
        self.player_id = details['player']
    if details.has('player_side'):
        self.player_side = details['player_side']
    if details.has('amount'):
        self.amount = int(details['amount'])


func _is_watched_building(building: BaseBuilding) -> bool:
    for position: Array in self.list:
        if building == self.board.map.model.get_tile2(position[0], position[1]).building.tile:
            return true
    return false


func _count_buildings_for_side(side: Variant) -> int:
    var count: int = 0
    var building: BaseBuilding

    if not side is Array:
        side = [side]

    for position: Array in self.list:
        building = self.board.map.model.get_tile2(position[0], position[1]).building.tile
        if building != null:
            for s: Variant in side:
                if building.side == s:
                    count += 1

    return count
