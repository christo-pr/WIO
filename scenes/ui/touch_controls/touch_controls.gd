extends CanvasLayer
class_name TouchControls

@export var player: Player
@export var deadzone: float = 0.18
@export var touch_look_sensitivity: float = 0.003

var move_vector: Vector2 = Vector2.ZERO

var _stick_finger: int = -1
var _look_finger: int = -1
var _mouse_stick: bool = false
var _mouse_look: bool = false
var _enabled: bool = true

@onready var _pointer: Pointer = player.get_node_or_null(^"Pointer")
@onready var _carrier: Carrier = player.get_node_or_null(^"Carrier")
@onready var _builder: Builder = player.get_node_or_null(^"Builder")
@onready var _margin: MarginContainer = $Margin
@onready var _stick: Control = $Margin/Hud/Stick
@onready var _knob: Control = $Margin/Hud/Stick/Knob
@onready var _jump: Button = $Margin/Hud/Jump
@onready var _sprint: Button = $Margin/Hud/Sprint
@onready var _pick: Button = $Margin/Hud/Point
@onready var _throw: Button = $Margin/Hud/Throw
@onready var _shop: Button = $Margin/Hud/Shop
@onready var _rotate_l: Button = $Margin/Hud/RotateL
@onready var _rotate_r: Button = $Margin/Hud/RotateR
@onready var _destroy: Button = $Margin/Hud/Destroy


func _ready() -> void:
	_jump.button_down.connect(func() -> void: Input.action_press("jump"))
	_jump.button_up.connect(func() -> void: Input.action_release("jump"))
	_sprint.button_down.connect(func() -> void: Input.action_press("sprint"))
	_sprint.button_up.connect(func() -> void: Input.action_release("sprint"))
	_pick.pressed.connect(_on_pick_pressed)
	_throw.pressed.connect(_on_throw_pressed)
	_shop.pressed.connect(_on_shop_pressed)
	_rotate_l.pressed.connect(_on_rotate_left_pressed)
	_rotate_r.pressed.connect(_on_rotate_right_pressed)
	_destroy.pressed.connect(_on_destroy_pressed)
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()


func _physics_process(_delta: float) -> void:
	_pick.visible = _show_picker_button()
	_throw.visible = _carrier.is_carrying() if _carrier != null else false
	_rotate_l.visible = _builder.is_building()
	_rotate_r.visible = _builder.is_building()
	_destroy.visible = _show_destroy_button()


func _input(event: InputEvent) -> void:
	if not _enabled:
		return
	if event is InputEventScreenTouch:
		_on_screen_touch(event)
	elif event is InputEventScreenDrag:
		_on_screen_drag(event)
	elif not DisplayServer.is_touchscreen_available():
		_on_desktop_mouse(event)


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if enabled:
		_margin.show()
		return
	_stick_finger = -1
	_look_finger = -1
	_mouse_stick = false
	_mouse_look = false
	_reset_stick()
	Input.action_release("jump")
	Input.action_release("sprint")
	_margin.hide()


func _apply_safe_area() -> void:
	var safe := DisplayServer.get_display_safe_area()
	var window := DisplayServer.window_get_size()
	_margin.add_theme_constant_override("margin_left", safe.position.x + 24)
	_margin.add_theme_constant_override("margin_top", safe.position.y + 24)
	_margin.add_theme_constant_override("margin_right", maxi(window.x - safe.end.x, 0) + 24)
	_margin.add_theme_constant_override("margin_bottom", maxi(window.y - safe.end.y, 0) + 24)


func _on_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _stick_finger == -1 and _stick.get_global_rect().has_point(event.position):
			_stick_finger = event.index
			_update_stick(event.position)
			get_viewport().set_input_as_handled()
		elif _look_finger == -1 and _in_look_area(event.position):
			_look_finger = event.index
			get_viewport().set_input_as_handled()
	elif event.index == _stick_finger:
		_stick_finger = -1
		_reset_stick()
	elif event.index == _look_finger:
		_look_finger = -1


func _on_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index == _stick_finger:
		_update_stick(event.position)
		get_viewport().set_input_as_handled()
	elif event.index == _look_finger:
		player.apply_look(event.relative, touch_look_sensitivity)
		get_viewport().set_input_as_handled()


func _on_desktop_mouse(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			if _stick.get_global_rect().has_point(event.position):
				_mouse_stick = true
				_update_stick(event.position)
			elif _in_look_area(event.position):
				_mouse_look = true
		else:
			_mouse_stick = false
			_mouse_look = false
			_reset_stick()
	elif event is InputEventMouseMotion and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if _mouse_stick:
			_update_stick(event.position)
		elif _mouse_look:
			player.apply_look(event.relative, touch_look_sensitivity)


func _in_look_area(pos: Vector2) -> bool:
	if _stick.get_global_rect().has_point(pos):
		return false
	if _jump.get_global_rect().has_point(pos):
		return false
	if _sprint.get_global_rect().has_point(pos):
		return false
	if _pick.get_global_rect().has_point(pos):
		return false
	if _throw.get_global_rect().has_point(pos):
		return false
	if _shop.get_global_rect().has_point(pos):
		return false
	if _rotate_l.get_global_rect().has_point(pos):
		return false
	if _rotate_r.get_global_rect().has_point(pos):
		return false
	if _destroy.get_global_rect().has_point(pos):
		return false
	return true


func _update_stick(global_pos: Vector2) -> void:
	var center := _stick.get_global_rect().get_center()
	var radius := minf(_stick.size.x, _stick.size.y) * 0.5
	var stick_offset := global_pos - center
	if stick_offset.length() > radius:
		stick_offset = stick_offset.normalized() * radius
	_knob.global_position = center + stick_offset - _knob.size * 0.5
	var raw := stick_offset / radius
	var mag := raw.length()
	if mag < deadzone:
		move_vector = Vector2.ZERO
		return
	var scaled := (mag - deadzone) / (1.0 - deadzone)
	move_vector = raw / mag * scaled


func _reset_stick() -> void:
	move_vector = Vector2.ZERO
	_knob.position = (_stick.size - _knob.size) * 0.5


func _show_destroy_button() -> bool:
	if _builder != null and _builder.is_building():
		return false
	if _carrier != null and _carrier.is_carrying():
		return false
	if _pointer == null:
		return false
	return _pointer.destroyable_target() != null


func _show_picker_button() -> bool:
	if _pointer != null:
		return _pointer.prompt_target() != null
	if _carrier != null and _carrier.is_carrying():
		return true
	return false


func _on_pick_pressed() -> void:
	if _pointer != null:
		_pointer.try_point()


func _on_throw_pressed() -> void:
	if _carrier != null:
		_carrier.throw_held()


func _on_shop_pressed() -> void:
	var press := InputEventAction.new()
	press.action = &"shop"
	press.pressed = true
	Input.parse_input_event(press)


func _on_rotate_left_pressed() -> void:
	_builder.rotate(-1)


func _on_rotate_right_pressed() -> void:
	_builder.rotate(1)


func _on_destroy_pressed() -> void:
	if _pointer != null:
		_pointer.try_destroy()
	_destroy.visible = false
