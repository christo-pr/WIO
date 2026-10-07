class_name Player
extends CharacterBody3D

enum PlayerMotion { IDLE, WALK, SPRINT, JUMP, FALL }

@export_group("Player settings")
@export var touch_controls_path: NodePath
@export var walk_speed: float = 4.0
@export var run_speed: float = 7.5
@export var acceleration: float = 24.0
@export var air_acceleration: float = 8.0
@export var deceleration: float = 32.0
@export var jump_velocity: float = 5.0
@export var max_jumps: int = 1
@export var jump_buffer_time: float = 0.12
@export var mouse_sensitivity: float = 0.002

var motion: PlayerMotion = PlayerMotion.IDLE
var jump_serial: int = 0

var _jumps_left: int = 1
var _jump_buffer: float = 0.0
var _last_jump_frame: int = -1
# Track second jump and apply animation
var _was_airborne: bool = false
var _jumped: bool = false
var _yaw: float = 0.0
var _pitch: float = 0.0
var _input_enabled: bool = true

@onready var _camera: PlayerCamera = %Camera

## Lifecycle
func _ready() -> void:
	_jumps_left = max_jumps
	if not DisplayServer.is_touchscreen_available():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if not _input_enabled:
		return
	if DisplayServer.is_touchscreen_available():
		return
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = (
			Input.MOUSE_MODE_VISIBLE
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		apply_look(event.relative, mouse_sensitivity)


func _physics_process(delta: float) -> void:
	if not _input_enabled:
		_jump_buffer = 0.0
		# direction = Vector3.ZERO so they coast to a stop
		return  # after the zeroed move, still move_and_slide

	var frame := Engine.get_process_frames()
	if Input.is_action_just_pressed("jump") and frame != _last_jump_frame:
		_jump_buffer = jump_buffer_time
		_last_jump_frame = frame

	if is_on_floor():
		_jumps_left = max_jumps
		if velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity += get_gravity() * delta

	_jump_buffer = maxf(_jump_buffer - delta, 0.0)
	if _jump_buffer > 0.0 and _jumps_left > 0:
		velocity.y = jump_velocity
		_jumps_left -= 1
		_jump_buffer = 0.0
		_jumped = true
		jump_serial += 1

	if Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y *= 0.5

	var move := _read_move()
	var direction := global_transform.basis * Vector3(move.x, 0.0, move.y)
	if direction.length() > 1.0:
		direction = direction.normalized()

	var speed := run_speed if Input.is_action_pressed("sprint") else walk_speed
	var accel := air_acceleration
	if is_on_floor():
		accel = deceleration if direction.length_squared() < 0.0001 else acceleration

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(direction * speed, accel * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	
	## Get the impact on the frame before moving
	var impact_y := velocity.y
	move_and_slide()
	## Then if is on floor on this frame but by falling
	## Meaning it lands kick
	if is_on_floor() and _was_airborne:
		_camera.add_land_kick(impact_y)
	_update_player_motion()


## Custom methods
func apply_look(relative: Vector2, sensitivity: float) -> void:
	_yaw -= relative.x * sensitivity
	_pitch -= relative.y * sensitivity
	_pitch = clampf(_pitch, deg_to_rad(-89.0), deg_to_rad(89.0))
	rotation.y = _yaw
	_camera.rotation.x = _pitch


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled


## Private methods
func _read_move() -> Vector2:
	var controls := get_node_or_null(touch_controls_path) as TouchControls
	if controls != null and controls.move_vector.length_squared() > 0.0001:
		return controls.move_vector
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back")


func _update_player_motion() -> void:
	var airborne := not is_on_floor()
	if airborne:
		# +Y is up. Rising after a jump plays jump. Everything else in the air plays fall,
		# including walking off a ledge.
		if _jumped and velocity.y > 0.2:
			motion = PlayerMotion.JUMP
		else:
			_jumped = false
			motion = PlayerMotion.FALL
		_was_airborne = true
		return
	_jumped = false
	_was_airborne = false
	var horiz := Vector2(velocity.x, velocity.z).length()
	if horiz >= run_speed * 0.72:
		motion = PlayerMotion.SPRINT
	elif horiz >= 0.35:
		motion = PlayerMotion.WALK
	elif horiz <= 0.15:
		motion = PlayerMotion.IDLE
	# Between 0.15 and 0.35, keep the previous grounded clip so idle/walk does not flicker.
