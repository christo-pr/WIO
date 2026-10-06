class_name BuildMenu
extends CanvasLayer

signal item_selected(entry: ShopItem)
signal opened
signal closed

@export var catalog: Array[ShopItem] = []
@export var player: Player
@export var touch_controls: TouchControls

var _open: bool = false
var _mouse_mode_before: Input.MouseMode

@onready var _margin: MarginContainer = $Margin
@onready var _items: VBoxContainer = $Margin/Center/Panel/List/Scroll/Items


func _ready() -> void:
	_margin.hide()
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()
	_rebuild()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		return
	if not _open:
		if event.is_action_pressed(&"shop"):
			_set_open(true)
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"shop") or event.is_action_pressed(&"ui_cancel"):
		_set_open(false)
		get_viewport().set_input_as_handled()
		return
	if event.is_action(&"point") or event.is_action(&"throw") or event.is_action(&"jump"):
		get_viewport().set_input_as_handled()


func _set_open(open: bool) -> void:
	_open = open
	_margin.visible = open
	if open:
		_mouse_mode_before = Input.mouse_mode
		if not DisplayServer.is_touchscreen_available():
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var first := _items.get_child(0) as Button
		if first != null:
			first.grab_focus()
		opened.emit()
	else:
		if not DisplayServer.is_touchscreen_available():
			Input.mouse_mode = _mouse_mode_before
		closed.emit()


func _apply_safe_area() -> void:
	var safe := DisplayServer.get_display_safe_area()
	var window := DisplayServer.window_get_size()
	_margin.add_theme_constant_override("margin_left", safe.position.x + 24)
	_margin.add_theme_constant_override("margin_top", safe.position.y + 24)
	_margin.add_theme_constant_override("margin_right", maxi(window.x - safe.end.x, 0) + 24)
	_margin.add_theme_constant_override("margin_bottom", maxi(window.y - safe.end.y, 0) + 24)


func _rebuild() -> void:
	for child in _items.get_children():
		child.queue_free()
	for entry in catalog:
		var button := Button.new()
		button.text = entry.display_name
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_item_pressed.bind(entry))
		_items.add_child(button)


func _on_item_pressed(entry: ShopItem) -> void:
	print(entry)
	item_selected.emit(entry)
	_set_open(false)
