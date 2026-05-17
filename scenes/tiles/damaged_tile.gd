extends MapObject

@onready var explosion: Variant = $"explosion"
@onready var smoke: GPUParticles3D = $"smoke"

@export var is_smoking: bool = false

func _ready() -> void:
    if self.is_smoking:
        self.smoke.set_emitting(true)

func show_explosion() -> void:
    self.explosion.explode_a_bit()
