extends RigidBody3D


@export var _open_angle: float = deg_to_rad(-90.0)
@export var _swing_time: float = 0.35


@onready var _door: MeshInstance3D = $Mesh/door
@onready var _pointable: Pointable = $Pointable

var _is_open: bool = false
var _tween: Tween


func _apply_door_state() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var target_y: float = _open_angle if _is_open else 0.0
	_pointable.label = "Close" if _is_open else "Open"
	_tween = create_tween().bind_node(self)
	_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(_door, "rotation:y", target_y, _swing_time).from_current()


func _on_pointable_pointed() -> void:
	_is_open = not _is_open
	_apply_door_state()
