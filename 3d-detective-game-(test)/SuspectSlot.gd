# SuspectSlot.gd - Updated with debug for evidence placement
extends PanelContainer

signal evidence_placed(evidence_id, suspect_id, is_correct)
signal evidence_removed(evidence_id, suspect_id)

var suspect_data: SuspectData
var suspect_id: String = ""
var placed_evidence: Dictionary = {}
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
			fingerprint_label.text = "FP"
			fingerprint_label.add_theme_font_size_override("font_size", 8)
	
	if shoe_label:
		shoe_label.text = data.get_display_shoe()
		shoe_label.visible = true
		shoe_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		shoe_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if evidence_container:
		evidence_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	visible = true
	show()
	print("✅ Suspect created: ", data.name)

func attempt_place_evidence(evidence_data: Dictionary) -> bool:
	print("\n📌 SUSPECT SLOT - attempt_place_evidence")
	print("   Suspect: ", suspect_data.name)
	print("   Evidence: ", evidence_data.get("name", "Unknown"))
	print("   Type: ", evidence_data.get("type", -1))
	print("   Match value: ", evidence_data.get("match_value", ""))
	
	var evidence_type = evidence_data.get("type", -1)
	var evidence_name = evidence_data.get("name", "Unknown")
	var match_value = evidence_data.get("match_value", "")
	
	if evidence_type == -1:
		print("   ❌ Invalid evidence type")
		return false
	
	if placed_evidence.has(evidence_type):
		print("   ❌ Already has this evidence type!")
		if case_board and case_board.has_method("show_message"):
			case_board.show_message("Already have " + evidence_name + " on " + suspect_data.name, Color(1, 0.5, 0))
		return false
	
	var is_correct = suspect_data.check_evidence_match(evidence_type, match_value)
	print("   Match result: ", is_correct)
	
	# Create icon
	var icon = TextureRect.new()
	if evidence_data.has("texture") and evidence_data.texture:
		icon.texture = evidence_data.texture
	icon.custom_minimum_size = Vector2(45, 45)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	if is_correct:
		icon.modulate = Color(0.3, 1, 0.3)
	else:
		icon.modulate = Color(1, 0.3, 0.3)
	
	placed_evidence[evidence_type] = icon
	
	if evidence_container:
		evidence_container.add_child(icon)
		print("   ✅ Icon added to evidence_container")
	else:
		print("   ❌ evidence_container is null!")
		return false
	
	# Animate
	var tween = create_tween()
	tween.tween_property(icon, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.1)
	
	evidence_placed.emit(evidence_data.id, suspect_id, is_correct)
	print("   ✅ Evidence placed successfully!")
	return true

func get_placed_evidence_count() -> int:
	return placed_evidence.size()

func is_culprit() -> bool:
	if placed_evidence.size() != 3:
		return false
	for icon in placed_evidence.values():
		if icon.modulate != Color(0.3, 1, 0.3):
			return false
	return true

func reset_slot():
	for icon in placed_evidence.values():
		icon.queue_free()
	placed_evidence.clear()

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("\n🖱️ SUSPECT CLICKED: ", suspect_data.name if suspect_data else "Unknown")
		if case_board:
			print("   case_board.current_phase: ", case_board.current_phase)
			if case_board.current_phase == case_board.GamePhase.PLACING_EVIDENCE:
				print("   ✅ In placement mode, attempting to place evidence")
				case_board.attempt_place_evidence_on_suspect(self)
			else:
				print("   ❌ Not in placement mode!")
		else:
			print("   ❌ case_board is null!")
