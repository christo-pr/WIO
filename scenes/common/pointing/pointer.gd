class_name Pointer
extends Node

signal target_changed(pointable: Pointable)

@export var camera: Camera3D
@export var player: CollisionObject3D
@export var aim_range: float = 8.0
@export_flags_3d_physics var collision_mask: int = 1

var target: Pointable

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
	#
	#if Input.is_action_just_pressed(&"point") and target != null:
		#target.point()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"point"):
		return
	if not DisplayServer.is_touchscreen_available() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	try_point()


func try_point() -> void:
	if target != null:
		target.point()

func is_pointing() -> bool:
	return target != null


func _query() -> Pointable:
	var space := camera.get_world_3d().direct_space_state
	var origin := camera.global_position
	var end := origin - camera.global_basis.z * aim_range
	var query := PhysicsRayQueryParameters3D.create(origin, end, collision_mask)
	query.exclude = [player.get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return null
	return _find_pointable(hit.collider as Node)


func _find_pointable(body: Node) -> Pointable:
	if body == null:
		return null
	for child in body.get_children():
		if child is Pointable:
			return child as Pointable
	return null
