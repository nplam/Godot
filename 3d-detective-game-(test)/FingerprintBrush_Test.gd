# fingerprintbrush_test.gd - Complete version with collision prevention and push-back
extends Node3D

var is_active: bool = false
var detected_surfaces: Array = []

# Node references
@onready var brush_model: Node3D = $BrushModel
@onready var detection_area: Area3D = $DetectionArea
@onready var collision_shape: CollisionShape3D = $DetectionArea/CollisionShape3D
@onready var hand: Node3D = get_parent()

# Player reference
var player: Node3D = null

# Collision state
var is_colliding: bool = false
var collision_normal: Vector3 = Vector3.ZERO

func _ready():
	# Find player
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().root.find_child("Player", true, false)
		if player:
			print("✅ Player found by name search")
	
	if player:
		print("✅ Player found: ", player.name)
	else:
		print("⚠️ Player not found - add player to 'player' group")
	
	hide()
	
	if detection_area:
		detection_area.monitoring = false
		detection_area.area_entered.connect(_on_area_entered)
		detection_area.area_exited.connect(_on_area_exited)
		print("✅ DetectionArea signals connected")
	else:
		print("❌ DetectionArea not found!")
	
	# Validate collision shape
	if collision_shape and collision_shape.shape:
		print("✅ Collision shape found: ", collision_shape.shape.get_class())
		print("   Position: ", collision_shape.position)
		print("   Scale: ", collision_shape.scale)
	else:
		print("❌ Collision shape missing or invalid!")
	
	print("🖌️ Brush ready with collision prevention")

func toggle_active():
	is_active = !is_active
	visible = is_active
	
	if detection_area:
		detection_area.monitoring = is_active
	
	print("🖌️ Brush toggled: ", "visible" if is_active else "hidden")

func _process(delta):
	if not is_active:
		return
	
	# Check if current position is valid (not inside a wall)
	if not is_position_valid(global_position):
		if not is_colliding:
			is_colliding = true
			print("🚨 Brush colliding with wall at: ", global_position)
		
		# Push back along camera direction
		push_out_of_wall(delta)
	else:
		if is_colliding:
			is_colliding = false
			print("✅ Brush no longer colliding")

func is_position_valid(pos: Vector3) -> bool:
	if not collision_shape or not collision_shape.shape:
		print("⚠️ No collision shape - can't check validity")
		return true
	
	var space = get_world_3d().direct_space_state
	var params = PhysicsShapeQueryParameters3D.new()
	params.shape = collision_shape.shape
	params.transform = Transform3D.IDENTITY.translated(pos)
	params.collision_mask = 1  # World layer
	
	# Build exclude list
	var exclude_list = [self, detection_area]
	
	# Try to find player if missing
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if player:
			print("✅ Player found and added to exclude list")
	
	if player and is_instance_valid(player):
		exclude_list.append(player)
	
	params.exclude = exclude_list
	
	var results = space.intersect_shape(params)
	
	if results.size() > 0:
		# SAFE DICTIONARY ACCESS - FIXED VERSION
		var collision_dict = results[0]
		
		# Get normal if available
		if collision_dict.has("normal"):
			collision_normal = collision_dict["normal"]
		else:
			collision_normal = Vector3.ZERO
			print("⚠️ No normal in collision data")
		
		# Optional debug info
		if collision_dict.has("collider"):
			var blocker = collision_dict["collider"]
			print("🚫 Brush blocked by: ", blocker.name, " (", blocker.get_class(), ")")
			
			# Show what layer the blocker is on (for debugging)
			if blocker is CollisionObject3D:
				print("   Layer: ", blocker.collision_layer)
		
		return false
	
	return true

func push_out_of_wall(delta):
	if not brush_model:
		return
	
	# Calculate push direction (away from camera)
	var camera = get_viewport().get_camera_3d()
	var push_dir = -camera.global_transform.basis.z  # Push away from where camera points
	
	# Apply push force (reduce strength)
	global_position += push_dir * delta * 3.0  # Reduced from 8.0 to 3.0
	
	# CRITICAL: Keep brush near hand
	var hand_pos = hand.global_position
	var max_distance = 0.5  # Maximum allowed distance from hand
	
	if global_position.distance_to(hand_pos) > max_distance:
		# Too far - snap back toward hand
		var dir_to_hand = (hand_pos - global_position).normalized()
		global_position += dir_to_hand * delta * 5.0
	
	# Visual feedback - shake brush
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(brush_model, "rotation:z", 0.15, 0.05)
	tween.tween_property(brush_model, "rotation:x", 0.1, 0.05)
	
	await get_tree().create_timer(0.05).timeout
	
	var return_tween = create_tween()
	return_tween.set_parallel(true)
	return_tween.tween_property(brush_model, "rotation:z", -0.1, 0.05)
	return_tween.tween_property(brush_model, "rotation:x", -0.05, 0.05)
	
	await get_tree().create_timer(0.05).timeout
	
	var reset_tween = create_tween()
	reset_tween.set_parallel(true)
	reset_tween.tween_property(brush_model, "rotation:z", 0.0, 0.05)
	reset_tween.tween_property(brush_model, "rotation:x", 0.0, 0.05)

# Detection signals
func _on_area_entered(area: Area3D):
	print("🚩 Something entered: ", area.name)
	print("   Class: ", area.get_class())
	print("   Groups: ", area.get_groups())
	
	if area.has_method("on_brush_dusted"):
		print("   ✅ Has on_brush_dusted method")
	else:
		print("   ❌ Missing on_brush_dusted method")
	
	if area.is_in_group("fingerprint_surface"):
		print("   ✅ It IS a fingerprint surface!")
		if not area in detected_surfaces:
			detected_surfaces.append(area)
			print("👆 Fingerprint surface detected: ", area.name)
	else:
		print("   ❌ Not in fingerprint_surface group")

func _on_area_exited(area: Area3D):
	if area in detected_surfaces:
		detected_surfaces.erase(area)
		print("👋 Fingerprint surface exited: ", area.name)

func _input(event):
	if not is_active:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if detected_surfaces.size() > 0:
			dust_nearest_surface()

func dust_nearest_surface():
	if detected_surfaces.size() == 0:
		return
	
	var closest = detected_surfaces[0]
	var closest_dist = global_position.distance_squared_to(closest.global_position)
	
	for surface in detected_surfaces:
		var dist = global_position.distance_squared_to(surface.global_position)
		if dist < closest_dist:
			closest = surface
			closest_dist = dist
	
	if closest.has_method("on_brush_dusted"):
		print("🖌️ Dusting fingerprint on: ", closest.name)
		closest.on_brush_dusted()
		play_dusting_animation()

func play_dusting_animation():
	if not brush_model:
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(brush_model, "position:y", brush_model.position.y - 0.02, 0.1)
	tween.tween_property(brush_model, "rotation:x", 0.1, 0.1)
	
	await get_tree().create_timer(0.1).timeout
	
	var return_tween = create_tween()
	return_tween.set_parallel(true)
	return_tween.tween_property(brush_model, "position:y", brush_model.position.y + 0.02, 0.1)
	return_tween.tween_property(brush_model, "rotation:x", 0.0, 0.1)
