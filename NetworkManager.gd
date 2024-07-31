extends Node

var client := HTTPClient.new()
var connection_status := OK
var url := "localhost"

const ERR_CUSTOM_CONNECTION_FAILED = -1  # Define a custom error code

func _ready():
	connect_to_server(url)
	print("NetworkManager initialized.")

func connect_to_server(current_url):	
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
		
func make_get_request(endpoint : String, query_params : Dictionary = {}, callback : Callable = Callable()):
	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		print("Not connected to server. Attempting to reconnect...")
		connect_to_server(url)
	
	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		print("Failed to reconnect to server.")
		return

	var query_string = _build_query_string(query_params)
	var full_url = endpoint + "?" + query_string
	
	var error = client.request(HTTPClient.METHOD_GET, full_url, [], "")
	if error != OK:
		print("Failed to send GET request: " + str(error))
		return
	
	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		client.poll()
		OS.delay_msec(100)  # Small delay to prevent busy-waiting

	var response_code = client.get_response_code()
	var rb = PackedByteArray()
	
	if response_code == 200:
		while client.get_status() == HTTPClient.STATUS_BODY:
			client.poll()
			var chunk = client.read_response_body_chunk()
			if chunk.size() == 0:
				await get_tree().process_frame
			else:
				rb = rb + chunk # Append to read buffer.
		
		var text = rb.get_string_from_ascii()

		if callback.is_valid():
			callback.call(text)
	
	else:
		print("Request failed. Response code: " + str(response_code))
		if callback.is_valid():
			callback.call({"error": "Request failed", "code": response_code})

func _build_query_string(params : Dictionary) -> String:
	var query_string = []
	for key in params.keys():
		query_string.append(str(key) + "=" + str(params[key]))
	return "&".join(query_string)
