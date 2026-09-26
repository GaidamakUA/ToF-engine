extends GroundTile
class_name DamagedTile

@onready var explosion: Variant = $"explosion"
@onready var smoke: GPUParticles3D = $"smoke"

var is_smoking: bool = false

func configure(resource: TileResource) -> void:
    super.configure(resource)
    var damage_resource: DamageTileResource = resource as DamageTileResource
    assert(damage_resource != null)
    self.is_smoking = damage_resource.is_smoking

func _ready() -> void:
    if self.is_smoking:
        self.smoke.set_emitting(true)

func show_explosion() -> void:
    self.explosion.explode_a_bit()
