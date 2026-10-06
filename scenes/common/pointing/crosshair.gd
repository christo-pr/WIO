extends CanvasLayer

@export var pointer: Pointer
@export var idle_color: Color = Color(1, 1, 1, 0.85)
@export var focus_color: Color = Color(1, 0.85, 0.3, 1)
@export var builder: Builder

@onready var _horizontal: ColorRect = %Horizontal
@onready var _vertical: ColorRect = %Vertical
@onready var _prompt: Label = %Prompt

func _ready() -> void:
	pointer.target_changed.connect(_on_target_changed)
	_on_target_changed(pointer.target)


func _process(_delta: float) -> void:
	_show(pointer.prompt_target())

func _on_target_changed(_pointable: Pointable) -> void:
	_show(pointer.prompt_target())

func _show(pointable: Pointable) -> void:
	## Check for building
	if builder != null and builder.is_building():
		var building_color := focus_color if builder.is_valid() else Color(1.0, 0.35, 0.35, 1.0)
		_horizontal.color = building_color
		_vertical.color = building_color
		_prompt.text = "Place" if builder.is_valid() else "Can't place"
		return
	## Just the text on the crosshair
	var color := idle_color if pointable == null else focus_color
	_horizontal.color = color
	_vertical.color = color
	_prompt.text = "" if pointable == null else pointable.label
