class_name Carrier
extends Node

@export var pointer: Pointer
@export var player: Player
@export var camera: Camera3D
@export var hold_point: Marker3D
@export var throw_speed: float = 7.0
@export var throw_loft: float = 0.25
@export var drop_speed: float = 2.5
@export var foot_distance: float = 0.75

var _held: Carryable
var _home: Node
var _layer: int
var _mask: int

func _physics_process(_delta: float) -> void:
	if _held == null:
		return
	_held.body().global_transform = hold_point.global_transform


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"throw"):
		return
	if not DisplayServer.is_touchscreen_available() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	throw_held()


func is_carrying() -> bool:
	return _held != null


func can_place() -> bool:
	if _held == null or pointer.hit_collider == null:
		return false
	if pointer.hit_normal.y < 0.7:
		return false
	return _find_child(pointer.hit_collider, Placeable) != null


func handle_point(pointable: Pointable) -> bool:
	if _held != null:
		if can_place():
			_place()
		else:
			_drop_at_feet()
		return true
	var carryable := _carryable_from(pointable)
	if carryable == null:
		return false
	_pickup(carryable)
	return true


func throw_held() -> void:
	if _held == null:
		return
	var body := _release_at(_held.body().global_transform)
	var aim := -camera.global_basis.z
	var direction := (aim + Vector3.UP * throw_loft).normalized()
	body.apply_central_impulse(direction * throw_speed * body.mass)


func _pickup(carryable: Carryable) -> void:
	var body := carryable.body()
	_held = carryable
	_home = body.get_parent()
	_layer = body.collision_layer
	_mask = body.collision_mask
	body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	body.freeze = true
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO
	body.collision_layer = 0
	body.collision_mask = 0
	pointer.exclude_rid(body.get_rid())
	body.reparent(hold_point, false)
	body.position = Vector3.ZERO
	body.rotation = Vector3.ZERO


func _place() -> void:
	var carryable := _held
	var pos = pointer.hit_position + pointer.hit_normal * carryable.rest_height
	var basis := Basis.from_euler(Vector3(0.0, player.rotation.y, 0.0))
	_release_at(Transform3D(basis, pos))


func _drop_at_feet() -> void:
	var body := _release_at(_held.body().global_transform)
	var forward := -player.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var direction := (Vector3.DOWN + forward * 0.35).normalized()
	body.apply_central_impulse(direction * drop_speed * body.mass)


func _release_at(xform: Transform3D) -> RigidBody3D:
	var carryable := _held
	var body := carryable.body()
	body.global_transform = xform
	body.reparent(_home, true)
	body.collision_layer = _layer
	body.collision_mask = _mask
	body.freeze = false
	body.sleeping = false
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO
	pointer.clear_exclude()
	_held = null
	return body


func _carryable_from(pointable: Pointable) -> Carryable:
	if pointable == null:
		return null
	return _find_child(pointable.get_parent(), Carryable) as Carryable


func _find_child(node: Node, type: Variant) -> Node:
	if node == null:
		return null
	for child in node.get_children():
		if is_instance_of(child, type):
			return child
	return null
