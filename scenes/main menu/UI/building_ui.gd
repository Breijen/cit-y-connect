extends Control

@export var building_name_label = Node
@export var max_occupants_label = Node
@export var claim_button = Node
@export var close_button = Node

var building_id: int
var apartment_id: int

func _ready():
	close_button.pressed.connect(_on_close_button_pressed)

func _on_close_button_pressed():
	queue_free()

func set_building_info(building_data: Dictionary):
	print(building_data)
	building_id = building_data["id"]
	
	if(building_data["user_apartment_id"]):
		apartment_id = building_data["user_apartment_id"]
	else:
		apartment_id
	
	building_name_label.text = building_data["building_name"]
	max_occupants_label.text = str(building_data["current_occupants"]) + " out of " + str(building_data["max_occupants"]) + " occupants"

	if(building_data["user_apartment_id"] == null):
		claim_button.text = "Claim apartment"
		claim_button.disabled = false
	elif(building_data["user_building_id"] == building_id):
		claim_button.text = "Enter apartment"
		claim_button.disabled = false
	else:
		claim_button.text = "You already have an apartment"
		claim_button.disabled = false
		
		
func _on_claim_button_pressed() -> void:
	if(apartment_id == 0):
		NetworkManager.create_apartment(building_id)
		queue_free()
		
