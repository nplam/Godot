extends Control

@onready var grid: GridContainer = $Background/Scroll/Grid
@onready var details_panel: Control = $Background/DetailsPanel
@onready var details_texture: TextureRect = $Background/DetailsPanel/TextureRect
@onready var details_label: RichTextLabel = $Background/DetailsPanel/RichTextLabel
@onready var close_button: Button = $Background/CloseButton

@export var slot_scene: PackedScene = preload("res://EvidenceSlot.tscn")

func _ready():
	print("🔧 EVIDENCE UI READY")
	print("   grid: ", grid)
	print("   slot_scene: ", slot_scene)
	
	# Connect to the evidence system signal
	if EvidenceSystem:
		EvidenceSystem.evidence_collected.connect(_on_evidence_collected)
		EvidenceSystem.evidence_removed.connect(_on_evidence_removed)
	else:
		print("❌ EvidenceSystem not found!")
	
	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
		print("   ✅ Close button connected")
	
	hide()
	if $Background:
		$Background.visible = false
	if details_panel:
		details_panel.hide()

func _input(event):
	if event.is_action_pressed("ui_focus_next"):  # Tab key
		visible = !visible
		print("📱 Evidence UI toggled: ", visible)
		if visible and $Background:
			$Background.visible = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			refresh()
		elif $Background:
			$Background.visible = false
			if details_panel:
				details_panel.hide()

func refresh():
	if not grid:
		print("❌ Grid is null!")
		return
	
	print("🔄 REFRESH STARTED")
	print("   Clearing grid...")
	for child in grid.get_children():
		child.queue_free()
	
	if not EvidenceSystem:
		print("❌ EvidenceSystem is null!")
		return
	
	var all_evidence = EvidenceSystem.get_all_evidence()
	print("   Evidence items: ", all_evidence.size())
	
	if all_evidence.size() == 0:
		print("   No evidence to display")
		return
	
	for evidence in all_evidence:
		print("\n   Processing: ", evidence.name)
		
		if not slot_scene:
			print("   ❌ slot_scene is null!")
			continue
			
		var slot = slot_scene.instantiate()
		if not slot:
			print("   ❌ Failed to instantiate slot!")
			continue
			
		# Connect signals
		slot.clicked.connect(_on_slot_clicked)
		slot.remove_requested.connect(_on_remove_requested)
		
		# Set up the slot
		if slot.has_method("setup"):
			slot.setup(evidence)
		else:
			print("   ❌ Slot has no setup method!")
			continue
		
		grid.add_child(slot)
		print("   ✅ Slot added")
	
	print("🔄 REFRESH COMPLETE")

func _on_evidence_collected(data):
	print("📦 Evidence collected: ", data.name)
	if visible:
		refresh()

func _on_evidence_removed(id):
	print("🗑️ Evidence removed signal: ", id)
	if visible:
		refresh()

func _on_slot_clicked(evidence_id):
	print("🖱️ Slot clicked: ", evidence_id)
	var data = EvidenceSystem.get_evidence(evidence_id)
	if data and details_panel and details_texture and details_label:
		details_texture.texture = data.icon
		details_label.text = "[b]" + data.name + "[/b]\n\n" + data.description
		details_panel.show()

func _on_remove_requested(evidence_id):
	print("🗑️ Remove requested for: ", evidence_id)
	
	# Get the data before removing
	var evidence_data = EvidenceSystem.get_evidence(evidence_id)
	if not evidence_data:
		print("   ❌ Evidence not found in system!")
		return
	
	# Get the world object reference
	var world_object = evidence_data.get("world_object")
	if world_object and is_instance_valid(world_object):
		print("   ✅ Found world object: ", world_object.name)
		# Call remove_from_inventory on the world object
		if world_object.has_method("remove_from_inventory"):
			world_object.remove_from_inventory()
			print("   ✅ Called remove_from_inventory on world object")
		else:
			print("   ❌ World object missing remove_from_inventory method")
	else:
		print("   ❌ World object reference is invalid or missing")
	
	# Remove from system
	var removed = EvidenceSystem.remove_evidence(evidence_id)
	if removed:
		print("   ✅ Removed from EvidenceSystem")
	
	if details_panel and details_panel.visible:
		details_panel.hide()

func _on_close_details_pressed():
	if details_panel:
		details_panel.hide()

func _on_close_button_pressed():
	visible = false
	if $Background:
		$Background.visible = false
	if details_panel:
		details_panel.hide()
