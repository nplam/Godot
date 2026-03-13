# fingerprintbrush_test.gd - with visual debug
extends Node3D

var is_active: bool = false

# Add a reference to the model
@onready var brush_model: Node3D = $BrushModel  # Adjust path as needed

func _ready():
	# Position it visibly for testing
	hide()
	print("🖌️ TEST brush ready - hidden")

func toggle_active():
	is_active = !is_active
	visible = is_active
	
	# Also toggle the model's visibility directly
	if brush_model:
		brush_model.visible = is_active
		print("   Model visibility set to: ", brush_model.visible)
	
	print("🖌️ TEST brush toggled: ", "visible" if is_active else "hidden")
