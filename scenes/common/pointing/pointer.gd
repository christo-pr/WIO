class_name Pointer
extends Node

signal target_changed(pointable: Pointable)

@export var camera: Camera3D
@export var player: Player
@export var aim_range: float = 8.0
@export_flags_3d_physics var collision_mask: int = 1


var target: Pointable
# Needed for the carrier/drop logic
var hit_position: Vector3
var hit_normal: Vector3 = Vector3.UP
var hit_collider: Node

var _extra_exclude: Array[RID] = []


func _physics_process(_delta: float) -> void:
	var next := _query()
	if next == target:
		return
	if target != null:
		target.unfocus()
	target = next
	if target != null:
		target.focus()
	target_changed.emit(target)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"point"):
		return
	if not DisplayServer.is_touchscreen_available() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	try_point()


func try_point() -> void:
	var carrier := get_parent().get_node_or_null(^"Carrier") as Carrier
	if carrier != null and carrier.handle_point(target):
		return
	if is_pointing():
		target.point()


func is_pointing() -> bool:
	return target != null


func exclude_rid(rid: RID) -> void:
	_extra_exclude = [rid]


func clear_exclude() -> void:
	_extra_exclude.clear()


func prompt_target() -> Pointable:
	if target == null:
		return null
	if not _body_has_placeable(target.get_parent()):
		return target
	var carrier := get_parent().get_node_or_null(^"Carrier") as Carrier
	if carrier != null and carrier.is_carrying():
		return target
	return null


func _query() -> Pointable:
	var space := camera.get_world_3d().direct_space_state
	var origin := camera.global_position
	var end := origin - camera.global_basis.z * aim_range
	var query := PhysicsRayQueryParameters3D.create(origin, end, collision_mask)
	query.exclude = [player.get_rid()] + _extra_exclude
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		hit_collider = null
		return null
	
	# Store this even if not find a pointable.
	# Carrier still needs to know if there's something
	hit_position = hit.position
	hit_normal = hit.normal
	hit_collider = hit.collider as Node
	return _find_pointable(hit.collider as Node)


func _find_pointable(body: Node) -> Pointable:
	if body == null:
		return null
	for child in body.get_children():
		if child is Pointable:
			return child as Pointable
	return null


func _body_has_placeable(body: Node) -> bool:
	if body == null:
		return false
	for child in body.get_children():
		if child is Placeable:
			return true
	return false
