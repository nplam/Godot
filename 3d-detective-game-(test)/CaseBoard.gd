# CaseBoard.gd - Updated with debug for evidence placement
extends Control

enum GamePhase { EXPLORATION, PLACING_EVIDENCE }

const EvidenceSlotScene = preload("res://EvidenceSlot.tscn")
const SuspectSlotScene = preload("res://SuspectSlot.tscn")

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

func _ready():
	_set_full_rect()
	
	print("\n🔍 CASEBOARD INITIALIZING...")
	
	if main_panel:
		main_panel.visible = true
		main_panel.show()
		main_panel.position = Vector2(100, 50)
	
	_show_all()
	
	if suspects_grid:
		suspects_grid.columns = 4
		suspects_grid.add_theme_constant_override("h_separation", 20)
	if evidence_grid:
		evidence_grid.columns = 3
		evidence_grid.add_theme_constant_override("h_separation", 20)
		evidence_grid.custom_minimum_size = Vector2(0, 180)
	
	_create_suspect_slots()
	
	if close_button:
		close_button.pressed.connect(_on_close)
	
	await get_tree().process_frame
	visible = false
	print("📋 CaseBoard ready - Press C to open")

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

func _create_suspect_slots():
	if not suspects_grid:
		print("❌ SuspectsGrid not found!")
		return
	
	for child in suspects_grid.get_children():
		child.queue_free()
	suspect_slots.clear()
	
	var suspects = SuspectData.get_all_suspects()
	print("Creating ", suspects.size(), " suspect slots...")
	
	for suspect in suspects:
		var slot = SuspectSlotScene.instantiate()
		suspects_grid.add_child(slot)
		slot.setup(suspect, suspect.id, self)
		slot.evidence_placed.connect(_on_evidence_placed)
		suspect_slots[suspect.id] = slot
		print("  ✅ Created: ", suspect.name)
	
	print("✅ Total suspects: ", suspect_slots.size())

func add_evidence(data):
	print("\n📋 Adding evidence: ", data.get("name", "Unknown"))
	
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
	print("\n🖱️ Evidence clicked: ", evidence_id)
	print("   Current phase: ", current_phase)
	
	for id in evidence_slots:
		if evidence_slots[id].evidence_id == evidence_id:
			print("   Found evidence slot, starting placement")
			start_placement(evidence_slots[id].evidence_data, evidence_slots[id])
			return
	print("   ❌ Evidence slot not found!")

func start_placement(evidence_data, evidence_node):
	print("\n🎯 START PLACEMENT MODE")
	print("   Evidence: ", evidence_data.get("name", "Unknown"))
	print("   Phase before: ", current_phase)
	
	if current_phase == GamePhase.PLACING_EVIDENCE:
		cancel_placement()
	
	current_phase = GamePhase.PLACING_EVIDENCE
	selected_evidence = evidence_data
	selected_evidence_node = evidence_node
	
	print("   Phase after: ", current_phase)
	
	evidence_node.modulate = Color(1, 1, 0.5)
	show_message("Click on a suspect to place " + evidence_data.name, Color(0.5, 0.8, 1))
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func cancel_placement():
	print("❌ Cancelling placement mode")
	if selected_evidence_node:
		selected_evidence_node.modulate = Color(1, 1, 1)
	
	current_phase = GamePhase.EXPLORATION
	selected_evidence = null
	selected_evidence_node = null
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	show_message("Placement cancelled", Color(0.8, 0.8, 0.8))

func attempt_place_evidence_on_suspect(suspect_slot):
	print("\n🔨 ATTEMPT PLACE ON SUSPECT")
	print("   Suspect: ", suspect_slot.suspect_data.name)
	print("   Current phase: ", current_phase)
	print("   Selected evidence: ", selected_evidence.get("name", "None") if selected_evidence else "None")
	
	if current_phase != GamePhase.PLACING_EVIDENCE:
		print("   ❌ Not in placement mode!")
		return false
	
	if not selected_evidence:
		print("   ❌ No selected evidence!")
		cancel_placement()
		return false
	
	print("   Attempting to place: ", selected_evidence.get("name", "Unknown"))
	var success = suspect_slot.attempt_place_evidence(selected_evidence)
	print("   Success: ", success)
	
	if success:
		if selected_evidence_node:
			selected_evidence_node.queue_free()
			evidence_slots.erase(selected_evidence.get("id", ""))
		cancel_placement()
		return true
	
	return false

func _on_evidence_placed(evidence_id, suspect_id, is_correct):
	var suspect = suspect_slots.get(suspect_id)
	
	if is_correct:
		show_message("✓ Correct! Evidence matches " + suspect.suspect_data.name, Color(0, 1, 0))
		for s in suspect_slots.values():
			if s.is_culprit():
				show_message("🎉 CASE SOLVED! " + s.suspect_data.name + " is the culprit! 🎉", Color(1, 1, 0))
				current_phase = GamePhase.EXPLORATION
				break
	else:
		show_message("✗ Wrong! Evidence doesn't match " + suspect.suspect_data.name, Color(1, 0, 0))

func show_message(msg, color):
	if feedback_label:
		feedback_label.text = msg
		feedback_label.modulate = color
		feedback_label.show()
		await get_tree().create_timer(2).timeout
		feedback_label.hide()
	else:
		print(msg)

func _on_close():
	hide()
	cancel_placement()
