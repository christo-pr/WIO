class_name PlayerVisuals
extends Node3D

@export var _player: Player
@export var _animation_player: AnimationPlayer


const BLEND := {
	Player.PlayerMotion.IDLE: 0.2,
	Player.PlayerMotion.WALK: 0.2,
	Player.PlayerMotion.SPRINT: 0.18,
	Player.PlayerMotion.JUMP: 0.1,
	Player.PlayerMotion.FALL: 0.16,
}

var _shown: int = -1
var _shown_jump_serial: int = -1


func _physics_process(_delta: float) -> void:
	var state := _player.motion
	var serial := _player.jump_serial
	var replay_jump := state == Player.PlayerMotion.JUMP and serial != _shown_jump_serial
	if state == _shown and not replay_jump:
		_apply_speed(state)
		return
	_shown = state
	_shown_jump_serial = serial
	var clip := _clip_for(state)
	_animation_player.play(clip, BLEND[state])
	_apply_speed(state)


func _clip_for(state: Player.PlayerMotion) -> StringName:
	match state:
		Player.PlayerMotion.WALK:
			return &"walk"
		Player.PlayerMotion.SPRINT:
			return &"sprint"
		Player.PlayerMotion.JUMP:
			return &"jump"
		Player.PlayerMotion.FALL:
			return &"fall"
		_:
			return &"idle"


func _apply_speed(state: Player.PlayerMotion) -> void:
	var horiz := Vector2(_player.velocity.x, _player.velocity.z).length()
	match state:
		Player.PlayerMotion.WALK:
			_animation_player.speed_scale = clampf(horiz / _player.walk_speed, 0.8, 1.25)
		Player.PlayerMotion.SPRINT:
			_animation_player.speed_scale = clampf(horiz / _player.run_speed, 0.85, 1.2)
		_:
			_animation_player.speed_scale = 1.0
