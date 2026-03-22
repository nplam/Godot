# CaseBoard.gd - Corrected paths
extends Control

const EvidenceSlotScene = preload("res://EvidenceSlot.tscn")

@onready var evidence_grid: GridContainer = $MainPanel/MarginContainer/EvidenceGrid
@onready var close_button: Button = $MainPanel/CloseButton
@onready var submit_button: Button = $MainPanel/SubmitButton

var evidence_slots = {}

func _ready():
	print("\n🔍 CASEBOARD DEBUG:")
	print("   evidence_grid: ", evidence_grid)
	print("   close_button: ", close_button)
	print("   submit_button: ", submit_button)
	
	add_to_group("case_board")
	print("📋 CaseBoard ready - press C to open\n")
	
	if close_button:
		close_button.pressed.connect(hide)
	if submit_button:
		submit_button.pressed.connect(_on_submit)
	
	hide()

func add_evidence(data: Dictionary):
	print("🔍 CaseBoard.add_evidence called with: ", data.name)
	
	if data.has("id") and data.id in evidence_slots:
		print("   Duplicate - ignoring")
		return
	
	if not evidence_grid:
		print("   ❌ evidence_grid is null! Check path.")
		return
	
	var slot = EvidenceSlotScene.instantiate()
	slot.setup(data, 1)  # 1 = CASE_BOARD mode
	
	evidence_grid.add_child(slot)
	evidence_slots[data.id] = slot
	print("📋 Added to case board: ", data.name)
	print("   Total slots: ", evidence_slots.size())

func _on_submit():
	var confirmed = []
	for id in evidence_slots:
		confirmed.append(id)
	print("📋 Case submitted with evidence: ", confirmed)
