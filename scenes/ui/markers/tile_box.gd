extends Node3D
class_name TileBox

@onready var mesh: MeshInstance3D = $"mesh"


func set_mesh_material(material: Resource) -> void:
	self.mesh.set_surface_override_material(0, material)
