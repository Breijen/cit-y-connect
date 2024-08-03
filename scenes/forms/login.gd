extends Control

var api_url := "http://localhost:8000/api/authenticate" # Adjust to your Laravel endpoint

@export var UsernameInput: Node
@export var PasswordInput: Node

var websocket = WebSocketPeer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _on_login_button_pressed() -> void:
	var username = UsernameInput.text
	var password = PasswordInput.text

	if username == "" or password == "":
		print("Please enter both email and password.")
		return

	print("Both filled")
	
	var query_params = {"username": username, "password": password}
	NetworkManager.make_post_request("/api/authenticate", query_params, Callable(self, "_on_request_completed"))

func _on_request_completed(body: String):
	
	var json = JSON.new()
	var error = json.parse(body)
	
	if error == OK:
		var data_received = json.data
		var user_id = json.data["user_id"]
		var token = json.data["token"]
		
		NetworkManager.connect_to_websocket(user_id, token);
		
		print(token)
		transition_to_lobby_scene()

func transition_to_lobby_scene():
	print("Transitioning to the lobby scene.")
	get_tree().change_scene_to_file("res://scenes/main menu/Lobby.tscn")
