extends PanelContainer

#@onready var icon: TextureRect = $MarginContainer/VBoxContainer/TextureRect
#@onready var label: Label = $MarginContainer/VBoxContainer/Label
@onready var icon: TextureRect = find_child("TextureRect", true, false)
@onready var label: Label = find_child("Label", true, false)

signal clicked(evidence_id)

var evidence_id: String

func setup(data: Dictionary):
	evidence_id = data.id
	print("Setting up slot for: ", data.name)
	print("  icon node: ", icon)
	print("  label node: ", label)
	if icon:
		if data.texture:
			icon.texture = data.texture
			print("  texture assigned")
		else:
			icon.texture = null
			print("  no texture, set to null")
	else:
		print("  ERROR: icon is null!")
	
	if label:
		label.text = data.name
		print("  label text set")
	else:
		print("  ERROR: label is null!")
		
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(evidence_id)

func _ready():
	print("=== EvidenceSlot Debug ===")
	print("Root: ", name)
	print("All children (recursive):")
	_print_children(self, 0)

func _print_children(node: Node, depth: int):
	for child in node.get_children():
		var indent = "  ".repeat(depth)
		print(indent + child.name)
		_print_children(child, depth + 1)
