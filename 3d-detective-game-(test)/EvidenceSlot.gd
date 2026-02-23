extends PanelContainer

# Declare the variable that will store this slot's evidence ID
var evidence_id: String
var pending_data: Dictionary = {}  # Store data until _ready

# Find the nodes using find_child (more reliable than paths)
@onready var icon: TextureRect = find_child("Icon", true, false)
@onready var label: Label = find_child("Label", true, false)

# Signal emitted when this slot is clicked
signal clicked(ev_id: String)

func _ready():
	print("=== ALL NODES IN EVIDENCE SLOT ===")
	print_all_children(self, 0)
	
	# Now that nodes are ready, apply any pending data
	if pending_data.size() > 0:
		apply_setup(pending_data)
		pending_data = {}

func print_all_children(node: Node, depth: int):
	var indent = "  ".repeat(depth)
	print(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		print_all_children(child, depth + 1)
		
func setup(data: Dictionary):
	# Store the data temporarily
	pending_data = data
	evidence_id = data.id
	
	# If we're already ready, apply immediately
	if is_inside_tree():
		apply_setup(data)

func apply_setup(data: Dictionary):
	# Set up the icon (image)
	if icon:
		if data.has("texture") and data.texture:
			icon.texture = data.texture
		else:
			icon.texture = null
		print("Icon configured for: ", data.name)
	else:
		print("Warning: Icon node not found in EvidenceSlot for: ", data.name)
	
	# Set up the label (text)
	if label:
		label.text = data.name
		print("Label configured for: ", data.name)
	else:
		print("Warning: Label node not found in EvidenceSlot for: ", data.name)

func _gui_input(event):
	# Detect mouse click on this slot
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(evidence_id)
