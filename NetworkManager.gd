extends Node

var client := HTTPClient.new()
var connection_status := OK
var url := "localhost"

var websocket = WebSocketPeer.new()

var interval: float = 10000.0
# Accumulated time
var time_accumulator: float = 0.0

const ERR_CUSTOM_CONNECTION_FAILED = -1  # Define a custom error code

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
			
func make_get_request(endpoint: String, query_params: Dictionary = {}, callback: Callable = Callable()):
	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		print("Not connected to server. Attempting to reconnect...")
		connect_to_server(url)
	
	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		print("Failed to reconnect to server.")
		return

	var query_string = _build_query_string(query_params)
	var full_url = endpoint
	
	var error = client.request(HTTPClient.METHOD_GET, full_url, [], "")
	if error != OK:
		print("Failed to send GET request: " + str(error))
		return

	# Poll for the response
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
		elif response_code == 302:
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

	if client.get_status() == HTTPClient.STATUS_DISCONNECTED:
		print("Connection was closed by the server.")
	
	# Reconnect after handling the request to ensure connection is ready for the next request
	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		connect_to_server(url)
		
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

func connect_to_websocket(token, delta: float) -> void:
	# Attempt to connect to the WebSocket server
	var url = "ws://localhost:8181/Echo"
	var err = websocket.connect_to_url(url)

	if err != OK:
		print("Error connecting to WebSocket server: ", err)
		return
	else:
		print("Connecting to WebSocket server...")


func _process(_delta):
	websocket.poll()

	if(websocket.get_ready_state() == 1):
		websocket.send_text("Hello Server!")
