extends Node

var client := HTTPClient.new()
var connection_status := OK
var url := "localhost"

var websocket = WebSocketPeer.new()

const ERR_CUSTOM_CONNECTION_FAILED = -1  # Define a custom error code
var connection_established := false

var auth_token: String = ""
var user_id: int

signal building_data_received(data: Dictionary)

func _ready():
	connect_to_server(url)
	print("NetworkManager initialized.")

func connect_to_server(current_url):	
	# Ensure the client is in the disconnected state before connecting
	if client.get_status() != HTTPClient.STATUS_DISCONNECTED:
		client.close()

	connection_status = client.connect_to_host(current_url, 8000)
	if connection_status != OK:
		print("Failed to connect to server: " + str(connection_status))
		return

	while client.get_status() == HTTPClient.STATUS_CONNECTING or client.get_status() == HTTPClient.STATUS_RESOLVING:
		client.poll()
		OS.delay_msec(100)  # Small delay to prevent busy-waiting

	if client.get_status() == HTTPClient.STATUS_CONNECTED:
		print("Connected to server.")
	else:
		print("Failed to connect to server.")
		connection_status = ERR_CUSTOM_CONNECTION_FAILED
			
func make_post_request(endpoint: String, query_params: Dictionary = {}, callback: Callable = Callable()):
	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		print("Not connected to server. Attempting to reconnect...")
		connect_to_server(url)
	
	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		print("Failed to reconnect to server.")
		return

	var query_string = _build_query_string(query_params)
	var full_url = endpoint
	
	var headers = [
		"Content-Type: application/json"
	]
	
	var body = JSON.new().stringify(query_params)
	
	var error = client.request(HTTPClient.METHOD_POST, endpoint, headers, body)
	
	if error != OK:
		print("Failed to send POST request: " + str(error))
		return
		
	while client.get_status() in [HTTPClient.STATUS_REQUESTING, HTTPClient.STATUS_BODY]:
		client.poll()
		OS.delay_msec(100)  # Prevent busy-waiting

		var response_code = client.get_response_code()
		if response_code == 0:
			continue  # Wait for the response
		elif response_code == 200:
			print("Response received. Reading body...")
			var rb = PackedByteArray()
			while client.get_status() == HTTPClient.STATUS_BODY:
				client.poll()
				var chunk = client.read_response_body_chunk()
				if chunk.size() == 0:
					await get_tree().process_frame
				else:
					rb.append_array(chunk)  # Append to read buffer.

			var text = rb.get_string_from_utf8()

			if callback.is_valid():
				callback.call(text)
		else:
			print("Request failed. Response code: " + str(response_code))
			if callback.is_valid():
				callback.call({"error": "Request failed", "code": response_code})
		break  # Exit the loop once done

func _build_query_string(params : Dictionary) -> String:
	var query_string = []
	for key in params.keys():
		query_string.append(str(key) + "=" + str(params[key]))
	return "&".join(query_string)

# WEBSOCKET 
func connect_to_websocket(id, token) -> void:
	# Attempt to connect to the WebSocket server
	auth_token = token
	user_id = id
	
	var url = "ws://localhost:8181/Lobby?token=" + auth_token
	
	var err = websocket.connect_to_url(url)

	if err != OK:
		print("Error connecting to WebSocket server: ", err)
		return
	else:
		print("Connecting to WebSocket server...")

func transition_to_lobby_scene():
	print("Transitioning to the lobby scene.")
	get_tree().change_scene_to_file("res://scenes/main menu/Lobby.tscn")

func handle_incoming_message(message: String):
	var json = JSON.new()
	var error = json.parse(message)
	
	if error == OK:
		var data_received = json.data
		if not data_received.has("type"):
			print("Error: Message type missing.")
			return
			
		if data_received.has("type") and data_received["type"] == "building_data":
			emit_signal("building_data_received", data_received["data"])
		else:
			print("Received unexpected message type or data format.")
	else:
		print("Failed to parse server message.")
		
func request_building_data(building_id: int):
	if websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var message = {
			"action": "getBuildingData",
			"building_id": building_id,
			"user_id": user_id,
		}
		var message_json = JSON.stringify(message)
		websocket.send_text(message_json)  # Send the request as a JSON string
		print("Requested data for building ID: %d" % building_id)
	else:
		print("WebSocket is not open. Cannot send message.")
		
func create_apartment(building_id: int):
	if websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var message = {
			"action": "createApartment",
			"building_id": building_id,
			"user_id": user_id,
		}
		var message_json = JSON.stringify(message)
		websocket.send_text(message_json)  # Send the request as a JSON string
		print("Attempting to create an apartment in: %d" % building_id)
	else:
		print("WebSocket is not open. Cannot send message.")

func _process(_delta):
	client.poll()
	websocket.poll()
	
	var state = websocket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		while websocket.get_available_packet_count() > 0:
			var packet = websocket.get_packet()
			if packet:
				handle_incoming_message(packet.get_string_from_utf8())
				
		if not connection_established:
			connection_established = true
			transition_to_lobby_scene()
			
	elif state == WebSocketPeer.STATE_CLOSING:
		pass

	# WebSocketPeer.STATE_CLOSED means the connection has fully closed.
	# It is now safe to stop polling.
	elif state == WebSocketPeer.STATE_CLOSED:
		if connection_established:
		# The code will be -1 if the disconnection was not properly notified by the remote peer.
			var code = websocket.get_close_code()
			print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
			set_process(false) # Stop processing.
