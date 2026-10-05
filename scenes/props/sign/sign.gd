extends StaticBody3D

@export var idle_color: Color = Color(0.55, 0.48, 0.36)
@export var focus_color: Color = Color(1.0, 0.82, 0.35)

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _pointable: Pointable = $Pointable

var _material: StandardMaterial3D

func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_color = idle_color
	_mesh.material_override = _material
	_pointable.focused.connect(_on_focused)
	_pointable.unfocused.connect(_on_unfocused)
	_pointable.pointed.connect(_on_pointed)

func _on_focused() -> void:
	_material.albedo_color = focus_color

func _on_unfocused() -> void:
	_material.albedo_color = idle_color

func _on_pointed() -> void:
	print("Pointed at ", name)
