class_name Pointable
extends Node

signal focused
signal unfocused
signal pointed

@export var label: String = "Point"

func focus() -> void:
	focused.emit()

func unfocus() -> void:
	unfocused.emit()

func point() -> void:
	pointed.emit()
