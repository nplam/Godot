# SuspectSlot.gd - Updated with 2-evidence culprit detection
extends PanelContainer

signal evidence_placed(evidence_id, suspect_id, is_correct)
signal evidence_removed(evidence_id, suspect_id)

var suspect_data: SuspectData
var suspect_id: String = ""
var placed_evidence: Dictionary = {}  # {evidence_type: evidence_info}
var case_board: Node = null

# Node references
var name_label: Label
var role_label: Label
var hair_label: Label
var shoe_label: Label
var evidence_container: HBoxContainer
var fingerprint_display: TextureRect
var fingerprint_label: Label

# Store data for when _ready runs
var pending_setup: Dictionary = {}

func _ready():
	_find_nodes()
	visible = true
	modulate = Color(1, 1, 1, 1)
	
	if not pending_setup.is_empty():
		_apply_setup(pending_setup)
		pending_setup.clear()

func _find_nodes():
	var vbox = $VBoxContainer
	if vbox:
		name_label = vbox.get_node_or_null("NameLabel")
		role_label = vbox.get_node_or_null("RoleLabel")
		hair_label = vbox.get_node_or_null("HairLabel")
		shoe_label = vbox.get_node_or_null("ShoeLabel")
		evidence_container = vbox.get_node_or_null("EvidenceContainer")
		fingerprint_display = vbox.get_node_or_null("FingerprintDisplay")
		if fingerprint_display:
			fingerprint_label = fingerprint_display.get_node_or_null("FingerprintLabel")

func setup(data: SuspectData, id: String, parent: Node):
	suspect_data = data
	suspect_id = id
	case_board = parent
	
	if not name_label:
		pending_setup = {"data": data, "id": id, "parent": parent}
		print("⏳ Setup deferred for: ", data.name)
		return
	
	_apply_setup({"data": data, "id": id, "parent": parent})

func _apply_setup(setup_data: Dictionary):
	var data = setup_data["data"]
	
	# Background
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.3, 1)
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.8, 0.6, 0.4, 1)
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", bg_style)
	
	if name_label:
		name_label.text = data.name
		name_label.visible = true
		name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if role_label:
		role_label.text = "Role: " + data.role
		role_label.visible = true
		role_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if hair_label:
		hair_label.text = data.get_display_hair()
		hair_label.visible = true
		hair_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		hair_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if fingerprint_display:
		fingerprint_display.visible = true
		fingerprint_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if data.fingerprint_texture:
			fingerprint_display.texture = data.fingerprint_texture
		else:
			var placeholder = StyleBoxFlat.new()
			placeholder.bg_color = Color(0.4, 0.4, 0.5, 1)
			fingerprint_display.add_theme_stylebox_override("panel", placeholder)
		if fingerprint_label:
			fingerprint_label.text = "FINGERPRINT"
			fingerprint_label.add_theme_font_size_override("font_size", 10)
	
	if shoe_label:
		shoe_label.text = data.get_display_shoe()
		shoe_label.visible = true
		shoe_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		shoe_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if evidence_container:
		evidence_container.alignment = BoxContainer.ALIGNMENT_CENTER
		evidence_container.add_theme_constant_override("separation", 8)
		evidence_container.custom_minimum_size = Vector2(180, 60)
		evidence_container.visible = true
	
	visible = true
	show()
	print("✅ Suspect created: ", data.name)

func attempt_place_evidence(evidence_data: Dictionary) -> bool:
	var evidence_type = evidence_data.get("type", -1)
	var evidence_name = evidence_data.get("name", "Unknown")
	var match_value = evidence_data.get("match_value", "")
	
	if evidence_type == -1:
		return false
	
	# Check if already has this evidence type
	if placed_evidence.has(evidence_type):
		if case_board and case_board.has_method("show_message"):
			case_board.show_message("Already have " + evidence_name + " on " + suspect_data.name, Color(1, 0.5, 0))
		return false
	
	# Check if matches using SuspectData
	var is_correct = suspect_data.check_evidence_match(evidence_type, match_value)
	
	# Create icon
	var icon = TextureRect.new()
	if evidence_data.has("texture") and evidence_data.texture:
		icon.texture = evidence_data.texture
	icon.custom_minimum_size = Vector2(45, 45)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.visible = true
	
	if is_correct:
		icon.modulate = Color(0.3, 1, 0.3)  # Green
	else:
		icon.modulate = Color(1, 0.3, 0.3)  # Red
	
	# Store evidence info with is_correct flag
	placed_evidence[evidence_type] = {
		"id": evidence_data.id,
		"name": evidence_name,
		"type": evidence_type,
		"match_value": match_value,
		"node": icon,
		"is_correct": is_correct
	}
	
	if evidence_container:
		evidence_container.add_child(icon)
		evidence_container.queue_sort()
	else:
		return false
	
	# Animate
	var tween = create_tween()
	tween.tween_property(icon, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Emit signal
	evidence_placed.emit(evidence_data.id, suspect_id, is_correct)
	
	return true

func get_placed_evidence_count() -> int:
	return placed_evidence.size()

func get_correct_evidence_count() -> int:
	"""Return number of correct evidence placed on this suspect"""
	var count = 0
	for evidence in placed_evidence.values():
		if evidence.is_correct:
			count += 1
	return count

func get_wrong_evidence_count() -> int:
	"""Return number of wrong evidence placed on this suspect"""
	var count = 0
	for evidence in placed_evidence.values():
		if not evidence.is_correct:
			count += 1
	return count

func is_culprit() -> bool:
	"""Check if suspect is the culprit (2 or more correct evidence)"""
	return get_correct_evidence_count() >= 2

func has_correct_evidence_type(evidence_type: int) -> bool:
	"""Check if a specific evidence type is correctly placed"""
	if placed_evidence.has(evidence_type):
		return placed_evidence[evidence_type].is_correct
	return false

func reset_slot():
	for evidence in placed_evidence.values():
		if evidence.node and is_instance_valid(evidence.node):
			evidence.node.queue_free()
	placed_evidence.clear()

func highlight_as_culprit():
	"""Flash the suspect slot to indicate they are the culprit"""
	var tween = create_tween()
	tween.set_loops(5)
	tween.tween_property(self, "modulate", Color(1, 1, 0, 1), 0.2)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if case_board:
			if case_board.current_phase == case_board.GamePhase.PLACING_EVIDENCE:
				case_board.attempt_place_evidence_on_suspect(self)
