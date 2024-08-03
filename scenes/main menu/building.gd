extends Node3D

@export_group("Building Stats")
@export var building_id: int
@export var max_occupants: int
@export var currentOccupants: int

@onready var building_info_ui := preload("res://scenes/main menu/UI/BuildingUI.tscn") # Adjust the path accordingly

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NetworkManager.connect("building_data_received", Callable(self, "_on_building_clicked_completed"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_building_clicked(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed == true:
			print("clicked")
			
			if building_id == null:
				print("Please enter a building ID.")
				return
				
			NetworkManager.request_building_data(building_id)

func _on_building_clicked_completed(response_data: Dictionary):
	if response_data:
		_show_building_info_ui(response_data)
	else:
		print("No data received or error in data.")
	
func _show_building_info_ui(building_data: Dictionary):
	var building_info_instance = building_info_ui.instantiate()
	building_info_instance.set_building_info(building_data)
	add_child(building_info_instance)
