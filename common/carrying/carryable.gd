class_name Carryable
extends Node

@export var rest_height: float = 0.5

func body() -> RigidBody3D:
	return get_parent() as RigidBody3D
