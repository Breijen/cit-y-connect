extends Node3D

@export_group("Building Stats")
@export var building_id: int
@export var max_occupants: int
@export var currentOccupants: int

@onready var building_info_ui := preload("res://scenes/main menu/UI/Building_UI.tscn") # Adjust the path accordingly

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

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
				
			var query_params = {"id": building_id}
			NetworkManager.make_get_request("/api/building", query_params, Callable(self, "_on_building_clicked_completed"))

func _on_building_clicked_completed(response_data):
	if(response_data):
		_show_building_info_ui(response_data)
	
func _show_building_info_ui(building_data):
	var building_info_instance = building_info_ui.instantiate()
	building_info_instance.set_building_info(building_data)
	add_child(building_info_instance)
