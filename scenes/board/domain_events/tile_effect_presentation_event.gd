class_name TileEffectPresentationEvent
extends ScriptPresentationEvent


enum Kind {
	SMOKE,
	BLESS,
}

var kind: Kind
var position: Vector2i


func _init(new_kind: Kind, new_position: Vector2i) -> void:
	self.kind = new_kind
	self.position = new_position
