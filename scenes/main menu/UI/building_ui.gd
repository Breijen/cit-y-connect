extends Control

@export var building_name_label = Node
@export var max_occupants_label = Node
@export var close_button = Node

func _ready():
	close_button.pressed.connect(_on_close_button_pressed)

func _on_close_button_pressed():
	queue_free()

func set_building_info(building_data: String):
	print(building_data)
	
	var json = JSON.new()
	var error = json.parse(building_data)
	
	if error == OK:
		var data_received = json.data
		
	
	
