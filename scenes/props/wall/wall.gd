@tool
class_name Wall
extends StaticBody3D

const BASE_SHAPE_SIZE := Vector3(1, 1.29, 0.05)
const BASE_SHAPE_POSITION := Vector3(0.5, 0.645, -0.02)

@export var override_materials: Array[StandardMaterial3D]:
	set(value):
		override_materials = value
		_apply_material()


@export var stretch := Vector3.ONE:
	set(value):
		stretch = value.max(Vector3(0.01, 0.01, 0.01))
		_apply_stretch()


func _ready() -> void:
	_apply_stretch()
	_apply_material()


func _apply_stretch() -> void:
	if not is_inside_tree():
		return
	scale = Vector3.ONE
	var mesh_node := get_node_or_null("Mesh") as MeshInstance3D
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if mesh_node == null or collision == null or not collision.shape is BoxShape3D:
		return
	mesh_node.scale = stretch
	var box := collision.shape as BoxShape3D
	box.size = BASE_SHAPE_SIZE * stretch
	collision.scale = Vector3.ONE
	collision.position = BASE_SHAPE_POSITION * stretch


func _apply_material() -> void:
	var mesh_node := get_node_or_null("Mesh") as MeshInstance3D
	if mesh_node == null:
		return
	var count := mini(mesh_node.get_surface_override_material_count(), override_materials.size())
	for i in count:
		var material := override_materials[i]
		if material == null:
			continue
		mesh_node.set_surface_override_material(i, material)
