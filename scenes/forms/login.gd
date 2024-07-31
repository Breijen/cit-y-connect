extends Control

var api_url := "http://localhost:8000/api/authenticate" # Adjust to your Laravel endpoint

@export var UsernameInput: Node
@export var PasswordInput: Node

var token := ""
var csrf_token := ""

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

	var http_request := HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

	var headers = [
		"Content-Type: application/json"
	]
	var body = JSON.new().stringify({"username": username, "password": password})

	var request_error = http_request.request(api_url, headers, HTTPClient.METHOD_POST, body)
	
	if request_error != OK:
		print("Failed to send request.")

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		print("Login successful! Token: " + token)
	else:
		var json = JSON.new()
		var response_data = json.parse(body.get_string_from_utf8())
		print("Login failed: " + str(response_code))
