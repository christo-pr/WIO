extends CanvasLayer

@export var pointer: Pointer
@export var idle_color: Color = Color(1, 1, 1, 0.85)
@export var focus_color: Color = Color(1, 0.85, 0.3, 1)

@onready var _horizontal: ColorRect = %Horizontal
@onready var _vertical: ColorRect = %Vertical
@onready var _prompt: Label = %Prompt

func _ready() -> void:
	pointer.target_changed.connect(_on_target_changed)
	_on_target_changed(pointer.target)

func _on_target_changed(pointable: Pointable) -> void:
	var color := idle_color if pointable == null else focus_color
	_horizontal.color = color
	_vertical.color = color
	_prompt.text = "" if pointable == null else pointable.label
