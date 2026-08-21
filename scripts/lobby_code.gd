class_name LobbyCode
extends RefCounted

const PREFIX := "TRI"
const VERSION := 1
const ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"


static func encode(address: String, port: int) -> String:
	var octets := address.strip_edges().split(".")
	if octets.size() != 4 or port < 1 or port > 65535:
		return ""

	var payload := PackedByteArray([VERSION])
	for octet_text in octets:
		if not octet_text.is_valid_int():
			return ""
		var octet := int(octet_text)
		if octet < 0 or octet > 255:
			return ""
		payload.append(octet)
	payload.append((port >> 8) & 0xff)
	payload.append(port & 0xff)
	payload.append(_checksum(payload))

	var encoded := _base32_encode(payload)
	var groups: Array[String] = []
	for index in range(0, encoded.length(), 4):
		groups.append(encoded.substr(index, mini(4, encoded.length() - index)))
	return PREFIX + "-" + "-".join(groups)


static func decode(code: String) -> Dictionary:
	var normalized := code.strip_edges().to_upper().replace("-", "").replace(" ", "")
	if normalized.begins_with(PREFIX):
		normalized = normalized.substr(PREFIX.length())
	var decoded := _base32_decode(normalized)
	if decoded.is_empty():
		return {"ok": false, "error": "That lobby code is not valid."}
	if decoded.size() != 8 or decoded[0] != VERSION:
		return {"ok": false, "error": "That lobby code uses an unsupported format."}
	var payload := decoded.slice(0, 7)
	if decoded[7] != _checksum(payload):
		return {"ok": false, "error": "That lobby code was typed incorrectly."}

	var address := "%d.%d.%d.%d" % [decoded[1], decoded[2], decoded[3], decoded[4]]
	var port := (decoded[5] << 8) | decoded[6]
	if port == 0:
		return {"ok": false, "error": "That lobby code does not contain a valid port."}
	return {"ok": true, "address": address, "port": port, "error": ""}


static func _checksum(bytes: PackedByteArray) -> int:
	var value := 0x5a
	for byte in bytes:
		value = ((value << 1) | (value >> 7)) & 0xff
		value = value ^ byte
	return value


static func _base32_encode(bytes: PackedByteArray) -> String:
	var output := ""
	var buffer := 0
	var bit_count := 0
	for byte in bytes:
		buffer = (buffer << 8) | byte
		bit_count += 8
		while bit_count >= 5:
			bit_count -= 5
			output += ALPHABET[(buffer >> bit_count) & 31]
	if bit_count > 0:
		output += ALPHABET[(buffer << (5 - bit_count)) & 31]
	return output


static func _base32_decode(text: String) -> PackedByteArray:
	var output := PackedByteArray()
	var buffer := 0
	var bit_count := 0
	for character in text:
		var value := ALPHABET.find(character)
		if value < 0:
			return PackedByteArray()
		buffer = (buffer << 5) | value
		bit_count += 5
		if bit_count >= 8:
			bit_count -= 8
			output.append((buffer >> bit_count) & 0xff)
	return output
