extends Node3D

const TILE_SIZE = 1.0  # Size of each tile, adjust as needed
var LENGTH : int
var WIDTH : int

var tile_scene = preload("res://scenes/Apartments/FloorTile.tscn")  # Preload the tile scene
var room_type: String = "default"  # Default value

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NetworkManager.request_apartment_data()
	NetworkManager.connect("user_apartment_data_received", Callable(self, "_on_apartment_data_received"))
	
func _on_apartment_data_received(response_data: Dictionary):
	var apartment_id = response_data["apartment_id"]
	var apartment_type = response_data["apartment_type"]
	var building_id = response_data["building_id"]
	
	print("Processing apartment:", apartment_type, "ID:", apartment_id)
	
	# Determine room type or size based on apartment_name or ID
	if apartment_type == "studio":
		room_type = "studio"
	elif apartment_type == "railroad":
		room_type = "railroad"
	else:
		room_type = "default"
	
	# Create the grid based on the room type
	create_grid(room_type)

func create_grid(room_type):
	match room_type:
		"default":
			LENGTH = 5
			WIDTH = 5
		"studio":
			LENGTH = 8
			WIDTH = 6
		"railroad":
			LENGTH = 10
			WIDTH = 5
	
	for x in range(LENGTH):
		for y in range(WIDTH):
			var tile_instance = tile_scene.instantiate()
			add_child(tile_instance)
			tile_instance.position = Vector3(x * TILE_SIZE, 0, y * TILE_SIZE)  # Position tiles on XZ plane

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
