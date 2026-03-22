extends StaticBody3D

func _ready():
	print("\n🔴 CLICKTEST LAYER DEBUG:")
	print("   Collision layer value: ", collision_layer)
	var layers = []
	for i in range(1, 10):
		if get_collision_layer_value(i):
			layers.append(str(i))
	print("   Active layers: ", "Layer " + ", Layer ".join(layers) if layers else "None")
	print("   Position: ", global_position)
	
	# Also print raycast mask from player
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_raycast_mask"):
		# You'll need to add this method to player
		pass

func get_interaction_text() -> String:
	return "CLICK ME!"

func _input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("🔥🔥🔥 SUCCESS! CLICK DETECTED! 🔥🔥🔥")
		
func interact():
	print("🖱️ interact() called - handling click")
	# Since we already handle in _input_event, we can just call that
	pass
