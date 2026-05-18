extends Object
class_name OnlineConnector

var API_PORT: int = 443
var API_LOCATION: String = "api.tof.p1x.in"
const API_USE_SSL: bool = true
const API_PRESENT_VERSION: String = "1.0.0"

var online_service: OnlineService = null

func _init(online: OnlineService) -> void:
	self.online_service = online

func _read_settings() -> void:
	var new_value: Variant = self.online_service.settings.get_option("online_domain")
	if new_value is String:
		self.API_LOCATION = new_value
	self.API_PORT = int(self.online_service.settings.get_option("online_port"))

func _get_request(resource: String, expect_json: bool = true) -> Dictionary[String, Variant]:
	return await self._request(resource, HTTPClient.METHOD_GET, "", expect_json)

func _post_request(resource: String, data: String = "", expect_json: bool = true) -> Dictionary[String, Variant]:
	return await self._request(resource, HTTPClient.METHOD_POST, data, expect_json)

func _request(resource: String, method: int, data: String, expect_json: bool = true) -> Dictionary[String, Variant]:
	return await self._request_any(self.API_LOCATION, resource, method, data, expect_json)

func _request_any(location: String, resource: String, method: int, data: String, expect_json: bool = true, expect_text: bool = true) -> Dictionary[String, Variant]:
	var error: Error
	var result: Dictionary[String, Variant] = {
		'status' : null,
		'response_code' : 0,
		'data' : {}
	}

	var http_client: HTTPClient = HTTPClient.new()
	var client_trusted_cas: X509Certificate = load("res://assets/czlowiekimadlo.crt") as X509Certificate
	error = http_client.connect_to_host(location, self.API_PORT, TLSOptions.client(client_trusted_cas))

	if error != OK:
		result['status'] = 'error'
		result['message'] = 'Could not open connection'
		return result

	while http_client.get_status() == HTTPClient.STATUS_CONNECTING or http_client.get_status() == HTTPClient.STATUS_RESOLVING:
		error = http_client.poll()
		await self.online_service.get_tree().create_timer(0.1).timeout

	if http_client.get_status() != HTTPClient.STATUS_CONNECTED:
		result['status'] = 'error'
		result['message'] = 'Could not connect'
		return result

	var headers: PackedStringArray = PackedStringArray([
		"User-Agent: ToF-II/" + self.API_PRESENT_VERSION,
		"Accept: */*"
	])
	if data != "":
		headers.append("Content-Type: application/json")
		error = http_client.request(method, resource, headers, data)
	else:
		error = http_client.request(method, resource, headers)

	if error != OK:
		result['status'] = 'error'
		result['message'] = 'Could not make request'
		return result

	while http_client.get_status() == HTTPClient.STATUS_REQUESTING:
		error = http_client.poll()
		await self.online_service.get_tree().create_timer(0.1).timeout

	if http_client.get_status() != HTTPClient.STATUS_BODY and http_client.get_status() != HTTPClient.STATUS_CONNECTED:
		result['status'] = 'error'
		result['message'] = 'Could not poll request'
		return result

	if (http_client.has_response()):
		result['headers'] = http_client.get_response_headers_as_dictionary()
		result['response_code'] = http_client.get_response_code()

		var read_buffer: PackedByteArray = PackedByteArray()
		var chunk: PackedByteArray

		while http_client.get_status() == HTTPClient.STATUS_BODY:
			error = http_client.poll()
			chunk = http_client.read_response_body_chunk()
			if chunk.size() == 0:
				await self.online_service.get_tree().create_timer(0.1).timeout
			else:
				read_buffer = read_buffer + chunk

		if expect_json:
			var response_text: String = read_buffer.get_string_from_utf8()
			var test_json_conv: JSON = JSON.new()
			test_json_conv.parse(response_text)
			result['data'] = test_json_conv.get_data()
			if result['data'] == null:
				result['status'] = 'error'
				result['message'] = 'Could not poll request'
				return result

			if result['data'].has('error'):
				result['status'] = 'error'
				if OS.is_debug_build():
					print(result)
			else:
				result['status'] = 'ok'
		else:
			result['status'] = 'ok'
			if expect_text:
				result['data'] = read_buffer.get_string_from_utf8()
			else:
				result['data'] = read_buffer

	return result
