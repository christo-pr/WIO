class_name PromptModal
extends Control

signal solved(entry: ShopItem)
signal closed

const _PADDING := 24

var _entry: ShopItem
var _keyboard_height := -1

@onready var _margin: MarginContainer = $Margin
@onready var _prompt: Label = $Margin/Center/Panel/Column/Prompt
@onready var _input: LineEdit = $Margin/Center/Panel/Column/Input
@onready var _error: Label = $Margin/Center/Panel/Column/Error
@onready var _submit: Button = $Margin/Center/Panel/Column/Buttons/Submit
@onready var _cancel: Button = $Margin/Center/Panel/Column/Buttons/Cancel


func _ready() -> void:
	hide()
	set_process(false)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_submit.pressed.connect(_submit_answer)
	_cancel.pressed.connect(close)
	_input.text_submitted.connect(func(_typed: String) -> void: _submit_answer())
	_input.text_changed.connect(func(_typed: String) -> void: _clear_error())
	get_viewport().size_changed.connect(_apply_insets)
	_apply_insets()


func _process(_delta: float) -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		return
	var height := DisplayServer.virtual_keyboard_get_height()
	if height == _keyboard_height:
		return
	_keyboard_height = height
	_apply_insets()


func open(entry: ShopItem) -> void:
	_entry = entry
	_input.text = ""
	_clear_error()
	_prompt.text = "Write the name of this object."
	_keyboard_height = -1
	show()
	set_process(true)
	_apply_insets()
	# edit() while hidden does not open the phone keyboard.
	_input.call_deferred("edit")


func close() -> void:
	_entry = null
	_input.unedit()
	_input.release_focus()
	if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		DisplayServer.virtual_keyboard_hide()
	set_process(false)
	_keyboard_height = -1
	_apply_insets()
	hide()
	closed.emit()


func is_open() -> bool:
	return visible


func _apply_insets() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		return
	var safe := DisplayServer.get_display_safe_area()
	var window := DisplayServer.window_get_size()
	var screen_scale := get_viewport().get_screen_transform().get_scale()
	var keyboard := 0
	if screen_scale.y > 0.0:
		keyboard = int(round(float(DisplayServer.virtual_keyboard_get_height()) / screen_scale.y))
	_margin.add_theme_constant_override("margin_left", _to_viewport_x(safe.position.x) + _PADDING)
	_margin.add_theme_constant_override("margin_top", _to_viewport_y(safe.position.y) + _PADDING)
	_margin.add_theme_constant_override("margin_right", _to_viewport_x(maxi(window.x - safe.end.x, 0)) + _PADDING)
	_margin.add_theme_constant_override(
		"margin_bottom",
		_to_viewport_y(maxi(window.y - safe.end.y, 0)) + _PADDING + keyboard
	)


func _to_viewport_x(screen_px: int) -> int:
	var scale_x := get_viewport().get_screen_transform().get_scale().x
	if scale_x <= 0.0:
		return screen_px
	return int(round(float(screen_px) / scale_x))


func _to_viewport_y(screen_px: int) -> int:
	var scale_y := get_viewport().get_screen_transform().get_scale().y
	if scale_y <= 0.0:
		return screen_px
	return int(round(float(screen_px) / scale_y))


func _submit_answer() -> void:
	if _entry == null:
		return
	var typed := _input.text.strip_edges()
	if typed == _entry.display_name:
		var entry := _entry
		close()
		solved.emit(entry)
		return
	_error.text = "That is not the name. Try again."
	_error.show()
	_input.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	_input.call_deferred("edit")


func _clear_error() -> void:
	_error.hide()
	_error.text = ""
	_input.remove_theme_color_override("font_color")
