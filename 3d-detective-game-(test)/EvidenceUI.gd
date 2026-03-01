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
	print("   slot_scene path: ", slot_scene.resource_path if slot_scene else "null")
	
	# Connect to the evidence system signal
	EvidenceSystem.evidence_collected.connect(_on_evidence_collected)
	hide()
	$Background.visible = false
	details_panel.hide()

func _input(event):
	if event.is_action_pressed("ui_focus_next"):  # Tab key
		visible = !visible
		print("📱 Evidence UI toggled: ", visible)
		if visible:
			# Show everything
			$Background.visible = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			refresh()  # Refresh whenever we open the inventory
		else:
			# Hide everything
			$Background.visible = false
			details_panel.hide()

func refresh():
	print("🔄 REFRESH STARTED")
	print("   Clearing grid...")
	for child in grid.get_children():
		print("      Removing: ", child.name)
		child.queue_free()
	
	print("   Getting evidence from system...")
	var all_evidence = EvidenceSystem.get_all_evidence()
	print("   EvidenceSystem returned: ", all_evidence)
	print("   Number of items: ", all_evidence.size())
	
	if all_evidence.size() == 0:
		print("   ⚠️ No evidence to display!")
		return
	
	for i in range(all_evidence.size()):
		var evidence = all_evidence[i]
		print("   Processing evidence ", i, ": ", evidence)
		print("      ID: ", evidence.id if evidence.has("id") else "missing")
		print("      Name: ", evidence.name if evidence.has("name") else "missing")
		
		print("      Instantiating slot...")
		var slot = slot_scene.instantiate()
		print("      Slot instantiated: ", slot)
		print("      Slot class: ", slot.get_class())
		print("      Slot script: ", slot.get_script())
		print("      Has setup method? ", slot.has_method("setup"))
		
		if slot.has_method("setup"):
			print("      Calling setup with evidence...")
			slot.setup(evidence)
			print("      Connecting clicked signal...")
			slot.clicked.connect(_on_slot_clicked)
			print("      Adding to grid...")
			grid.add_child(slot)
			print("      ✅ Slot added successfully")
		else:
			print("      ❌ ERROR: Slot missing setup method!")
	print("🔄 REFRESH COMPLETE")

func _on_evidence_collected(id, data):
	print("📦 Evidence collected signal received: ", id)
	print("   Data: ", data)
	# If the inventory is currently open, refresh immediately
	if visible:
		print("   Inventory open, refreshing...")
		refresh()
	else:
		print("   Inventory closed, will show on next open")

func _on_slot_clicked(evidence_id):
	print("🖱️ Slot clicked: ", evidence_id)
	var data = EvidenceSystem.get_evidence(evidence_id)
	if data:
		print("   Showing details for: ", data.name)
		details_texture.texture = data.texture
		details_label.text = "[b]" + data.name + "[/b]\n\n" + data.description
		details_panel.show()
	else:
		print("   ⚠️ No data found for evidence_id: ", evidence_id)

func _on_close_details_pressed():
	print("🔒 Details panel closed")
	details_panel.hide()

func _on_close_button_pressed():
	print("❌ Evidence UI closed by button")
	visible = false
	$Background.visible = false
	details_panel.hide()
