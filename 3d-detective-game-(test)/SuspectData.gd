# SuspectData.gd - With actual fingerprint images
extends Resource
class_name SuspectData

# Properties for a single suspect
@export var id: String = ""
@export var name: String = ""
@export var role: String = ""
@export var hair_color: String = ""
@export var fingerprint_id: String = ""
@export var fingerprint_texture: Texture2D
@export var shoe_type: String = ""
@export var portrait: Texture2D

# Static method to get all suspects
static func get_all_suspects() -> Array:
	return [
		_create_suspect_1(),
		_create_suspect_2(),
		_create_suspect_3(),
		_create_suspect_4()
	]

# Static method to get a specific suspect by ID
static func get_suspect_by_id(suspect_id: String) -> SuspectData:
	for suspect in get_all_suspects():
		if suspect.id == suspect_id:
			return suspect
	return null

# Private static methods to create each suspect
static func _create_suspect_1() -> SuspectData:
	var suspect = SuspectData.new()
	suspect.id = "suspect_1"
	suspect.name = "Mr. Bobby"
	suspect.role = "Owner"
	suspect.hair_color = "Brown"
	suspect.fingerprint_id = "fp_001"
	# Load fingerprint image
	suspect.fingerprint_texture = load("res://assets/fingerprints/fingerprint_1.png")
	suspect.shoe_type = "loafers"
	return suspect

static func _create_suspect_2() -> SuspectData:
	var suspect = SuspectData.new()
	suspect.id = "suspect_2"
	suspect.name = "Mrs. Bobby"
	suspect.role = "Wife"
	suspect.hair_color = "Red"
	suspect.fingerprint_id = "fp_002"
	suspect.fingerprint_texture = load("res://assets/fingerprints/fingerprint_2.png")
	suspect.shoe_type = "high heels"
	return suspect

static func _create_suspect_3() -> SuspectData:
	var suspect = SuspectData.new()
	suspect.id = "suspect_3"
	suspect.name = "Luela"
	suspect.role = "Maid"
	suspect.hair_color = "Blond"
	suspect.fingerprint_id = "fp_003"
	suspect.fingerprint_texture = load("res://assets/fingerprints/fingerprint_3.png")
	suspect.shoe_type = "flats"
	return suspect

static func _create_suspect_4() -> SuspectData:
	var suspect = SuspectData.new()
	suspect.id = "suspect_4"
	suspect.name = "Hector"
	suspect.role = "Security Guard"
	suspect.hair_color = "Brown"
	suspect.fingerprint_id = "fp_004"
	suspect.fingerprint_texture = load("res://assets/fingerprints/fingerprint_4.png")
	suspect.shoe_type = "loafers"
	return suspect

# Helper method to check if evidence matches this suspect
func check_evidence_match(evidence_type: int, match_value: String) -> bool:
	match evidence_type:
		0:  # SHOEPRINT
			return match_value.to_lower().strip_edges() == shoe_type.to_lower().strip_edges()
		1:  # FINGERPRINT
			return match_value == fingerprint_id
		2:  # HAIR
			var normalized_match = match_value.to_lower().replace(" hair", "").strip_edges()
			var normalized_hair = hair_color.to_lower().replace(" hair", "").strip_edges()
			return normalized_match == normalized_hair
	return false

# Helper method to get display-ready strings
func get_display_hair() -> String:
	return hair_color + " hair" if not hair_color.ends_with("hair") else hair_color

func get_display_shoe() -> String:
	return "Shoe: " + shoe_type

func _to_string() -> String:
	return "Suspect: %s (ID: %s)" % [name, id]
