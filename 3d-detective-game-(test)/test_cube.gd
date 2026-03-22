# TestCube.gd
extends StaticBody3D

func _ready():
	collision_layer = 4
	print("🔵 Test cube (StaticBody3D) ready at: ", global_position)

func get_interaction_text() -> String:
	return "Test Cube"

func _input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("🖱️ CLICKED on test cube!")
