class_name Buildable
extends Node

enum Surface { WORLD_FLOOR, PLACEABLE }

## WORLD_FLOOR: furniture. Hits the World layer, rejects tables (they have Placeable).
## PLACEABLE: cups and other small items. The hit body must have a Placeable child.
@export var surface: Surface = Surface.WORLD_FLOOR

## How far to push the root along the hit normal.
## 0 if the scene origin is the bottom contact point.
## Half the height if the origin is the mesh center.
@export var lift: float = 0.0

## Floor and table tops pass. Walls fail. 1 is perfectly up, 0 is a wall.
@export var min_up_dot: float = 0.7

@export var yaw_step_degrees: float = 45.0
