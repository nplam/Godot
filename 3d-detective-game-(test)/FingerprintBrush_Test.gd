# fingerprintbrush_test.gd - Complete version with detection, clipping, and player exclusion
extends Node3D

var is_active: bool = false
var detected_surfaces: Array = []

# Node references
@onready var brush_model: Node3D = $BrushModel
@onready var detection_area: Area3D = $DetectionArea
@onready var collision_shape: CollisionShape3D = $DetectionArea/CollisionShape3D
@onready var hand: Node3D = get_parent()

# Player reference (will be found in _ready)
var player: Node3D = null

# Target position for smooth movement
var target_position: Vector3
var movement_speed: float = 15.0

func _ready():
	# Find player node (assumes player is in group "player")
	player = get_tree().get_first_node_in_group("player")
	if player:
		print("✅ Player found: ", player.name)
	else:
		print("⚠️ Player not found - add player to 'player' group")
	
	hide()
	
	# Configure detection area
	if detection_area:
		detection_area.monitoring = false
		detection_area.area_entered.connect(_on_area_entered)
		detection_area.area_exited.connect(_on_area_exited)
		print("✅ DetectionArea signals connected")
	else:
		print("❌ DetectionArea not found!")
	
	print("🖌️ TEST brush ready - hidden")

func toggle_active():
	is_active = !is_active
	visible = is_active
	
	# Toggle detection monitoring
	if detection_area:
		detection_area.monitoring = is_active
	
	# Toggle model visibility
	if brush_model:
		brush_model.visible = is_active
	
	print("🖌️ TEST brush toggled: ", "visible" if is_active else "hidden")

func _process(delta):
	if not is_active:
		return
	
	# Calculate target position relative to hand
	var hand_transform = hand.global_transform
	target_position = hand_transform.origin + hand_transform.basis * Vector3(0.1, -0.2, 0.15)
	
	# Check if we can move there
	if can_move_to(target_position):
		# Smoothly move toward target
		global_position = global_position.lerp(target_position, delta * movement_speed)
	else:
		# Can't move - play feedback
		play_hit_feedback()
	
	# Keep brush upright (counter hand rotation)
	var target_rot = hand.rotation
	target_rot.x = 0  # Don't tilt up/down
	target_rot.z = -0.1  # Slight natural angle
	rotation = rotation.lerp(target_rot, delta * 10.0)

func can_move_to(pos: Vector3) -> bool:
	if not collision_shape or not collision_shape.shape:
		return true
	
	var space = get_world_3d().direct_space_state
	var params = PhysicsShapeQueryParameters3D.new()
	params.shape = collision_shape.shape
	params.transform = Transform3D.IDENTITY.translated(pos)
	params.collision_mask = 1  # World layer
	
	# Build exclude list - everything we don't want to collide with
	var exclude_list = [self, detection_area, hand]
	if player:
		exclude_list.append(player)
	params.exclude = exclude_list
	
	var results = space.intersect_shape(params)
	
	# Debug output - see what's blocking
	if results.size() > 0:
		var blocker = results[0].collider
		print("🚫 Brush blocked by: ", blocker.name, " (", blocker.get_class(), ")")
		
		# Show what layer the blocker is on (for debugging)
		if blocker is CollisionObject3D:
			print("   Layer: ", blocker.collision_layer)
	
	return results.size() == 0

func play_hit_feedback():
	if not brush_model:
		return
	
	var tween = create_tween()
	tween.tween_property(brush_model, "rotation:z", 0.1, 0.05)
	tween.tween_property(brush_model, "rotation:z", -0.1, 0.05)
	tween.tween_property(brush_model, "rotation:z", 0.0, 0.05)

# Detection signals
func _on_area_entered(area: Area3D):
	print("🚩 Something entered: ", area.name)
	
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
