extends Control

@onready var grid: GridContainer = $Background/Scroll/Grid
@onready var details_panel: Control = $Background/DetailsPanel
@onready var details_texture: TextureRect = $Background/DetailsPanel/TextureRect
@onready var details_label: RichTextLabel = $Background/DetailsPanel/RichTextLabel
@onready var close_button: Button = $Background/CloseButton

@export var slot_scene: PackedScene = preload("res://EvidenceSlot.tscn")

func _ready():
	EvidenceSystem.evidence_collected.connect(_on_evidence_collected)
	hide()  # Start hidden
	$Background.visible = false  # Ensure background starts hidden
	details_panel.hide()

func _input(event):
	if event.is_action_pressed("ui_focus_next"):  # Tab key
		visible = !visible
		if visible:
			# Show everything
			$Background.visible = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			refresh()
		else:
			# Hide everything
			$Background.visible = false
			details_panel.hide()

func refresh():
	# Clear existing slots
	for child in grid.get_children():
		child.queue_free()
	
	# Add a slot for each collected evidence
	for evidence in EvidenceSystem.get_all_evidence():
		var slot = slot_scene.instantiate()
		slot.setup(evidence)
		slot.clicked.connect(_on_slot_clicked)
		grid.add_child(slot)

func _on_evidence_collected(id, data):
	if visible:  # Only refresh if UI is visible
		refresh()

func _on_slot_clicked(evidence_id):
	var data = EvidenceSystem.get_evidence(evidence_id)
	if data:
		details_texture.texture = data.texture
		details_label.text = "[b]" + data.name + "[/b]\n\n" + data.description
		details_panel.show()

func _on_close_details_pressed():
	details_panel.hide()

func _on_close_button_pressed():
	visible = false
	$Background.visible = false
	details_panel.hide()
