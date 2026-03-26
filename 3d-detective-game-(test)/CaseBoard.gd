# CaseBoard.gd - Updated for manually placed suspect slots
extends Control

enum GamePhase { EXPLORATION, PLACING_EVIDENCE }

const EvidenceSlotScene = preload("res://EvidenceSlot.tscn")

# Simple node references
@onready var evidence_grid = $MainPanel/MarginContainer/MainVBox/EvidenceGrid
@onready var suspects_grid = $MainPanel/MarginContainer/MainVBox/SuspectsGrid
@onready var close_button = $MainPanel/CloseButton
@onready var feedback_label = $MainPanel/FeedbackLabel
@onready var main_panel = $MainPanel

# Game state
var evidence_slots = {}
var suspect_slots = {}
var current_phase = GamePhase.EXPLORATION
var selected_evidence = null
var selected_evidence_node = null
var game_solved = false

func _ready():
	_set_full_rect()
	
	print("\n🔍 CASEBOARD INITIALIZING...")
	print("📝 feedback_label found: ", feedback_label != null)
	
	if main_panel:
		main_panel.visible = true
		main_panel.show()
		main_panel.position = Vector2(100, 50)
	
	_show_all()
	
	# Configure grids
	if suspects_grid:
		suspects_grid.columns = 4
		suspects_grid.add_theme_constant_override("h_separation", 20)
		
		# Collect existing suspect slots from scene (manually placed in editor)
		for child in suspects_grid.get_children():
			if child.has_method("get_correct_evidence_count"):
				suspect_slots[child.suspect_id] = child
				child.evidence_placed.connect(_on_evidence_placed)
				print("✅ Found suspect: ", child.suspect_name)
	
	if evidence_grid:
		evidence_grid.columns = 3
		evidence_grid.add_theme_constant_override("h_separation", 20)
		evidence_grid.custom_minimum_size = Vector2(0, 180)
	
	if close_button:
		close_button.pressed.connect(_on_close)
	
	await get_tree().process_frame
	visible = false
	print("📋 CaseBoard ready - Press C to open")
	print("   Total suspects found: ", suspect_slots.size())

func _set_full_rect():
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

func _show_all():
	if main_panel:
		main_panel.visible = true
		main_panel.show()
	
	var margin = $MainPanel/MarginContainer
	if margin:
		margin.visible = true
	
	var vbox = $MainPanel/MarginContainer/MainVBox
	if vbox:
		vbox.visible = true
	
	if suspects_grid:
		suspects_grid.visible = true
		suspects_grid.custom_minimum_size = Vector2(0, 320)
	
	if evidence_grid:
		evidence_grid.visible = true
		evidence_grid.custom_minimum_size = Vector2(0, 180)

func add_evidence(data):
	print("\n📋 Adding evidence: ", data.get("name", "Unknown"))
	
	if game_solved:
		print("   Game already solved - ignoring")
		return
	
	if not evidence_grid:
		print("   ❌ Evidence grid is null!")
		return
	
	var slot = EvidenceSlotScene.instantiate()
	slot.setup(data, 0)
	slot.clicked.connect(_on_evidence_clicked)
	slot.visible = true
	slot.show()
	
	evidence_grid.add_child(slot)
	evidence_slots[data.id] = slot
	evidence_grid.queue_sort()
	
	print("   ✅ Evidence added, total: ", evidence_slots.size())

func _on_evidence_clicked(evidence_id):
	if game_solved:
		print("Game already solved - cannot place more evidence")
		return
		
	print("\n🖱️ Evidence clicked: ", evidence_id)
	
	for id in evidence_slots:
		if evidence_slots[id].evidence_id == evidence_id:
			start_placement(evidence_slots[id].evidence_data, evidence_slots[id])
			return
	print("   ❌ Evidence slot not found!")

func start_placement(evidence_data, evidence_node):
	if game_solved:
		return
		
	if current_phase == GamePhase.PLACING_EVIDENCE:
		cancel_placement()
	
	current_phase = GamePhase.PLACING_EVIDENCE
	selected_evidence = evidence_data
	selected_evidence_node = evidence_node
	
	evidence_node.modulate = Color(1, 1, 0.5)
	show_message("Click on a suspect to place " + evidence_data.name, Color(0.5, 0.8, 1))
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func cancel_placement():
	if selected_evidence_node:
		selected_evidence_node.modulate = Color(1, 1, 1)
	
	current_phase = GamePhase.EXPLORATION
	selected_evidence = null
	selected_evidence_node = null
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	show_message("Placement cancelled", Color(0.8, 0.8, 0.8))

func attempt_place_evidence_on_suspect(suspect_slot):
	if game_solved:
		return false
		
	if current_phase != GamePhase.PLACING_EVIDENCE:
		return false
	
	if not selected_evidence:
		cancel_placement()
		return false
	
	var success = suspect_slot.attempt_place_evidence(selected_evidence)
	
	if success:
		if selected_evidence_node:
			selected_evidence_node.queue_free()
			evidence_slots.erase(selected_evidence.get("id", ""))
		cancel_placement()
		return true
	
	return false

func _on_evidence_placed(evidence_id, suspect_id, is_correct):
	if game_solved:
		return
		
	var suspect = suspect_slots.get(suspect_id)
	
	if is_correct:
		show_message("✓ Correct! Evidence matches " + suspect.suspect_name, Color(0, 1, 0))
		
		# Count correct evidence for this suspect
		var correct_count = suspect.get_correct_evidence_count()
		print("   Suspect ", suspect.suspect_name, " now has ", correct_count, " correct evidence")
		
		# Check if culprit found (2 or more correct evidence)
		if correct_count >= 2:
			var victory_msg = "🎉 CASE SOLVED! " + suspect.suspect_name + " is the culprit! 🎉"
			
			print("\n" + "=".repeat(50))
			print(victory_msg)
			print("=".repeat(50))
			
			# Show in feedback label
			if feedback_label:
				feedback_label.text = victory_msg
				feedback_label.modulate = Color(1, 1, 0)
				feedback_label.show()
				print("✅ Victory message sent to feedback_label")
			
			# Create popup dialog
			var popup = AcceptDialog.new()
			popup.dialog_text = victory_msg
			popup.title = "🎉 CASE SOLVED! 🎉"
			popup.popup_centered()
			add_child(popup)
			popup.popup()
			print("✅ Victory popup created")
			
			# Create temporary label on screen
			var temp_label = Label.new()
			temp_label.text = victory_msg
			temp_label.add_theme_font_size_override("font_size", 24)
			temp_label.add_theme_color_override("font_color", Color(1, 1, 0))
			temp_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
			temp_label.add_theme_constant_override("outline_size", 2)
			temp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			temp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			temp_label.size = Vector2(600, 100)
			temp_label.position = Vector2(200, 280)
			temp_label.visible = true
			add_child(temp_label)
			print("✅ Victory label created")
			
			# Auto remove after 5 seconds
			await get_tree().create_timer(5.0).timeout
			temp_label.queue_free()
			
			game_solved = true
			current_phase = GamePhase.EXPLORATION
			_on_culprit_found(suspect_id)
	else:
		show_message("✗ Wrong! Evidence doesn't match " + suspect.suspect_name, Color(1, 0, 0))

func _on_culprit_found(suspect_id: String):
	var culprit_slot = suspect_slots.get(suspect_id)
	if culprit_slot:
		var victory_msg = "🎉 CASE SOLVED! " + culprit_slot.suspect_name + " is the culprit! 🎉"
		
		# Console output
		print("\n" + "=".repeat(50))
		print(victory_msg)
		print("=".repeat(50))
		
		# Show in feedback label
		if feedback_label:
			feedback_label.text = victory_msg
			feedback_label.modulate = Color(1, 1, 0)
			feedback_label.show()
			print("✅ Victory message shown on feedback label")
		
		# Flash the culprit slot
		culprit_slot.highlight_as_culprit()
		
		# Disable all evidence slots
		for slot in evidence_slots.values():
			slot.modulate = Color(0.5, 0.5, 0.5)
			slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_message(msg, color):
	print("📢 show_message: ", msg)
	if feedback_label:
		feedback_label.text = msg
		feedback_label.modulate = color
		feedback_label.show()
		
		# Don't auto-hide victory messages
		if "CASE SOLVED" not in msg and "Correct" not in msg:
			await get_tree().create_timer(2).timeout
			feedback_label.hide()
	else:
		print("   ❌ feedback_label is null!")

func _on_close():
	hide()
	cancel_placement()

func reset_game():
	print("🔄 Resetting case board...")
	game_solved = false
	
	if feedback_label:
		feedback_label.text = ""
		feedback_label.hide()
	
	for slot in evidence_slots.values():
		slot.queue_free()
	evidence_slots.clear()
	
	for suspect_id in suspect_slots.keys():
		var slot = suspect_slots[suspect_id]
		slot.reset_slot()
	
	cancel_placement()
