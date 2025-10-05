@tool
extends Node3D

@export_node_path("Node3D") var door_path: NodePath   # The rotating part
@export var closed_rotation: Vector3 = Vector3.ZERO   # Closed rotation
@export var open_rotation: Vector3 = Vector3(0, 90, 0) # Open rotation
@export var open_by_default: bool = false : set = _set_open_by_default

var _door: Node3D
var _is_open: bool = false

func _ready() -> void:
	_door = get_node(door_path)
	if open_by_default:
		open()
	else:
		close()

func open() -> void:
	if _door:
		_door.rotation_degrees = open_rotation
		_is_open = true

func close() -> void:
	if _door:
		_door.rotation_degrees = closed_rotation
		_is_open = false

# This makes the inspector toggle update instantly in the editor
func _set_open_by_default(value: bool) -> void:
	open_by_default = value
	if not Engine.is_editor_hint():
		return
	if not _door and door_path:
		_door = get_node(door_path)
	if _door:
		if value:
			open()
		else:
			close()
