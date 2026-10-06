class_name Builder
extends Node

@export var camera: Camera3D
@export var player: Player
@export var props_parent: Node3D
@export var build_range: float = 6.0
## World (1) + Props (4). Player is excluded from the ray, included in the overlap test.
@export_flags_3d_physics var ray_mask: int = 5
## World (1) + Player (2) + Props (4).
@export_flags_3d_physics var block_mask: int = 7

var _entry: ShopItem
var _ghost: Node3D
var _buildable: Buildable
var _yaw: float = 0.0
var _valid: bool = false
var _support_rid: RID = RID()
var _mat_ok: StandardMaterial3D
var _mat_bad: StandardMaterial3D

func _ready() -> void:
	_mat_ok = _blueprint_material(Color(0.35, 0.65, 1.0, 0.45))
	_mat_bad = _blueprint_material(Color(1.0, 0.35, 0.35, 0.45))


func _input(event: InputEvent) -> void:
	if _ghost == null:
		return
	if event.is_action_pressed(&"point"):
		confirm()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"shop"):
		cancel()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"rotate_left"):
		rotate(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"rotate_right"):
		rotate(1)
		get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if _ghost == null or _buildable == null:
		return
	var hit := _ray()
	if hit.is_empty() or not _surface_ok(hit):
		_valid = false
		_support_rid = RID()
		_ghost.visible = false
		return
	_support_rid = hit.rid
	var pos: Vector3 = hit.position + hit.normal * _buildable.lift
	_ghost.global_transform = Transform3D(Basis.from_euler(Vector3(0.0, _yaw, 0.0)), pos)
	_ghost.visible = true
	_valid = not _blocked()
	_paint(_ghost, _mat_ok if _valid else _mat_bad)


func is_building() -> bool:
	return _ghost != null


func is_valid() -> bool:
	return _valid


func start(entry: ShopItem) -> void:
	cancel()
	if entry == null or entry.scene == null or props_parent == null:
		push_error("Builder: shop item needs a scene, and Builder needs props_parent.")
		return
	var node := entry.scene.instantiate()
	_buildable = _find_buildable(node)
	if _buildable == null:
		node.free()
		push_error("Builder: %s has no Buildable child." % entry.display_name)
		return
	_entry = entry
	_yaw = player.rotation.y
	_ghost = node
	props_parent.add_child(_ghost)
	_silence(_ghost)
	_ghost.visible = false


func confirm() -> void:
	if _ghost == null or not _valid or _entry == null or _entry.scene == null:
		return
	var placed := _entry.scene.instantiate()
	props_parent.add_child(placed)
	placed.global_transform = _ghost.global_transform
	_clear_ghost()


func cancel() -> void:
	_clear_ghost()


func rotate(dir: int) -> void:
	if _buildable == null:
		return
	_yaw += deg_to_rad(_buildable.yaw_step_degrees) * float(dir)


func _ray() -> Dictionary:
	var space := camera.get_world_3d().direct_space_state
	var origin := camera.global_position
	var end := origin - camera.global_basis.z * build_range
	var query := PhysicsRayQueryParameters3D.create(origin, end, ray_mask)
	query.exclude = [player.get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = false
	return space.intersect_ray(query)


func _surface_ok(hit: Dictionary) -> bool:
	if hit.normal.y < _buildable.min_up_dot:
		return false
	var body := hit.collider as Node
	var on_placeable := _has_placeable(body)
	if _buildable.surface == Buildable.Surface.PLACEABLE:
		return on_placeable
	if on_placeable:
		return false
	if body is CollisionObject3D:
		return (body as CollisionObject3D).collision_layer & 1 != 0
	if body is CSGShape3D:
		return (body as CSGShape3D).collision_layer & 1 != 0
	return false


func _blocked() -> bool:
	var space := _ghost.get_world_3d().direct_space_state
	var exclude: Array[RID] = [_support_rid]
	if _ghost is CollisionObject3D:
		exclude.append((_ghost as CollisionObject3D).get_rid())
	for shape_node in _ghost.find_children("*", "CollisionShape3D", true, false):
		var col := shape_node as CollisionShape3D
		if col == null or col.shape == null:
			continue
		var params := PhysicsShapeQueryParameters3D.new()
		params.shape = col.shape
		params.transform = col.global_transform
		params.collision_mask = block_mask
		params.exclude = exclude
		params.collide_with_bodies = true
		params.collide_with_areas = false
		if not space.intersect_shape(params, 1).is_empty():
			return true
	return false


func _silence(node: Node) -> void:
	if node is CollisionObject3D:
		var body := node as CollisionObject3D
		body.collision_layer = 0
		body.collision_mask = 0
	if node is RigidBody3D:
		var rigid := node as RigidBody3D
		rigid.freeze = true
		rigid.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	for shape_node in node.find_children("*", "CollisionShape3D", true, false):
		var col := shape_node as CollisionShape3D
		if col != null:
			col.disabled = true


func _paint(node: Node, mat: Material) -> void:
	for mesh_node in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := mesh_node as MeshInstance3D
		if mesh != null:
			mesh.material_override = mat


func _clear_ghost() -> void:
	if _ghost != null:
		_ghost.queue_free()
	_ghost = null
	_buildable = null
	_entry = null
	_valid = false
	_support_rid = RID()


func _find_buildable(node: Node) -> Buildable:
	for child in node.get_children():
		if child is Buildable:
			return child as Buildable
	return null


func _has_placeable(node: Node) -> bool:
	if node == null:
		return false
	for child in node.get_children():
		if child is Placeable:
			return true
	return false


func _blueprint_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	return mat
