class_name PlayerCamera
extends Camera3D

@export var walk_frequency := 1.8
@export var walk_vertical := 0.018
@export var walk_horizontal := 0.01
@export var sprint_frequency := 2.5
@export var sprint_vertical := 0.032
@export var sprint_horizontal := 0.016
@export var blend_speed := 8.0
@export var roll_degrees := 0.45
@export var land_dip := 0.04
@export var land_decay := 3.0
@export var land_min_speed := 4.5

var _player: Player
var _phase := 0.0
var _weight := 0.0
var _kick := 0.0


func _ready() -> void:
	_player = get_parent() as Player


func add_land_kick(fall_speed: float) -> void:
	var speed := -fall_speed
	if speed < land_min_speed:
		return
	var amount := clampf((speed - land_min_speed) / 8.0, 0.0, 1.0)
	_kick = maxf(_kick, amount)


func _process(delta: float) -> void:
	var motion := _player.motion
	var moving := motion == Player.PlayerMotion.WALK or motion == Player.PlayerMotion.SPRINT
	var sprinting := motion == Player.PlayerMotion.SPRINT
	var blend := 1.0 - exp(-blend_speed * delta)
	_weight = lerpf(_weight, 1.0 if moving else 0.0, blend)

	var horiz := Vector2(_player.velocity.x, _player.velocity.z).length()
	var ref_speed := _player.run_speed if sprinting else _player.walk_speed
	var freq := sprint_frequency if sprinting else walk_frequency
	if horiz > 0.2:
		_phase += delta * freq * clampf(horiz / ref_speed, 0.0, 1.25) * TAU

	var vert := sprint_vertical if sprinting else walk_vertical
	var side := sprint_horizontal if sprinting else walk_horizontal
	var bob_y := sin(_phase) * vert * _weight
	var bob_x := cos(_phase * 0.5) * side * _weight

	_kick = maxf(_kick - land_decay * delta, 0.0)
	var kick_y := -land_dip * _kick * _kick

	v_offset = bob_y + kick_y
	h_offset = bob_x
	rotation.z = deg_to_rad(roll_degrees) * cos(_phase * 0.5) * _weight
