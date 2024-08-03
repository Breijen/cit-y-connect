extends Node3D

@export var default_color: Color = Color(1, 1, 1)  # White
@export var hover_color: Color = Color(1, 1, 0.5)  # Light yellow for hover

@export var mesh_instance: Node

func _ready():
	_set_default_color()

# Set the default color
func _set_default_color():
	var material = StandardMaterial3D.new()
	material.albedo_color = default_color
	mesh_instance.material_override = material

# Set the hover color
func _set_hover_color():
	var material = StandardMaterial3D.new()
	material.albedo_color = hover_color
	mesh_instance.material_override = material

# Detect when the mouse enters the tile
func _on_mouse_entered():
	_set_hover_color()

# Detect when the mouse exits the tile
func _on_mouse_exited():
	_set_default_color()
