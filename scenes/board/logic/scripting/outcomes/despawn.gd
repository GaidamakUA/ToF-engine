extends BaseOutcome
class_name DespawnOutcome

var who: Variant = null
var fields: Array[Dictionary] = []

func _execute(_metadata: Dictionary[String, Variant]) -> void:
    if self.who != null:
        self.model.destroy_unit(self.who, 0, false)
    elif not self.fields.is_empty():
        var positions: Array[Vector2i] = []
        var x_index: int
        var y_index: int
        for rectangle: Dictionary in self.fields:
            x_index = rectangle["x1"]

            while x_index <= rectangle["x2"]:
                y_index = rectangle["y1"]
                while y_index <= rectangle["y2"]:
                    positions.append(Vector2i(x_index, y_index))
                    y_index += 1
                x_index += 1
        self.model.destroy_units(positions)

func _ingest_details(details: Dictionary[String, Variant]) -> void:
    if details.has("who"):
        self.who = Vector2i(details['who'][0], details['who'][1])
    if details.has("fields"):
        self.fields.assign(details['fields'])
