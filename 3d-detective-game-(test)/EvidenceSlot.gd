extends PanelContainer

var evidence_id: String
var evidence_data: Dictionary

@onready var icon: TextureRect = find_child("Icon", true, false)
@onready var label: Label = find_child("Label", true, false)
@onready var remove_button: Button = find_child("RemoveButton", true, false)

signal clicked(ev_id: String)
signal remove_requested(ev_id: String)

func _ready():
	print("🔧 EvidenceSlot ready")
	print("   Icon found: ", icon != null)
	print("   Label found: ", label != null)
	print("   Remove button found: ", remove_button != null)
	
	if remove_button:
		remove_button.pressed.connect(_on_remove_pressed)

func setup(data: Dictionary):
	print("📦 EvidenceSlot setup for: ", data.name)
	
	evidence_data = data
	evidence_id = data.id
	
	# Set label
	if label:
		label.text = data.name
		print("   ✅ Label set to: ", data.name)
	else:
		print("   ❌ Label is null - attempting to find again")
		label = find_child("Label", true, false)
		if label:
			label.text = data.name
			print("   ✅ Label found and set on second attempt")
	
	# Set icon
	if icon:
		print("   ✅ Icon node exists")
		if data.icon:
			icon.texture = data.icon
			print("   ✅ Icon texture assigned")
			print("      Texture size: ", data.icon.get_size())
			icon.visible = true
			icon.modulate = Color.WHITE
			# No need for update() - texture assignment is enough
		else:
			print("   ⚠️ No icon data")
			create_placeholder()
	else:
		print("   ❌ Icon node is null - attempting to find again")
		icon = find_child("Icon", true, false)
		if icon:
			print("   ✅ Icon found on second attempt")
			if data.icon:
				icon.texture = data.icon
				icon.visible = true
				icon.modulate = Color.WHITE
			else:
				create_placeholder()
		else:
			print("   ❌ Still cannot find Icon node")
			create_placeholder()

func create_placeholder():
	# Create a colored rectangle as placeholder so we can see the slot
	var placeholder = ColorRect.new()
	placeholder.color = Color(0.5, 0.5, 0.8, 0.8)
	placeholder.size = Vector2(80, 80)
	placeholder.position = Vector2(10, 10)
	add_child(placeholder)
	print("   ✅ Added placeholder ColorRect")

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(evidence_id)

func _on_remove_pressed():
	remove_requested.emit(evidence_id)
