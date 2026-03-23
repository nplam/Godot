# BlueLight_Fresh.gd - With full raycast debug
extends Area3D

# Track light state
var is_on: bool = false
var visual_light: SpotLight3D = null
var glasses_overlay = null
var player_raycast: RayCast3D = null
var current_detected_fingerprint = null

func _ready():
	print("\n🔵🔵🔵 BLUE LIGHT INITIALIZING 🔵🔵🔵")
	print("   Node: ", name)
	print("   Node type: ", get_class())
	print("   Parent: ", get_parent().name)
	
	# Find visual light (BlueLight)
	for child in get_parent().get_children():
		if child.name == "BlueLight" and child is SpotLight3D:
			visual_light = child
			print("   ✅ Found BlueLight as direct sibling")
			break
	
	if not visual_light:
		visual_light = get_parent().find_child("BlueLight", true, false)
		if visual_light:
			print("   ✅ Found BlueLight via find_child")
	
	# Find player's raycast
	var player = get_tree().root.find_child("Player", true, false)
	if player:
		player_raycast = player.get_node("Head/Camera3D/InteractionRay")
		if player_raycast:
			print("   ✅ Found player raycast")
			print("   Raycast enabled: ", player_raycast.enabled)
			print("   Raycast collision mask: ", player_raycast.collision_mask)
		else:
			print("   ❌ Could not find InteractionRay!")
	
	# Find glasses overlay
	glasses_overlay = get_tree().root.find_child("OrangeGlassesOverlay", true, false)
	print("   Glasses overlay: ", glasses_overlay)
	
	# Start disabled
	if visual_light:
		visual_light.visible = false
	monitoring = false
	
	# Connect body signals for proximity detection
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	print("🔵 Blue Light ready\n")

func set_active(active: bool):
	is_on = active
	if visual_light:
		visual_light.visible = active
		print("   Blue light visibility set to: ", active)
	monitoring = active
	print("🔵 Blue Light active: ", active)
	
	if not active:
		reset_all_evidence()

func _process(delta):
	if not is_on:
		return
	
	# Check if orange glasses are on
	var glasses_on = glasses_overlay and glasses_overlay.is_on if glasses_overlay else false
	if not glasses_on:
		if current_detected_fingerprint and current_detected_fingerprint.has_method("reset_glow"):
			current_detected_fingerprint.reset_glow()
		current_detected_fingerprint = null
		return
	
	if not player_raycast:
		return
	
	# RAYCAST DEBUG - Print every few frames to avoid spam
	var frame_count = Engine.get_frames_drawn()
	if frame_count % 60 == 0:  # Print once per second (approx)
		print("\n🔍 RAYCAST DEBUG:")
		print("   Raycast enabled: ", player_raycast.enabled)
		print("   Raycast is_colliding: ", player_raycast.is_colliding())
		if player_raycast.is_colliding():
			var collider = player_raycast.get_collider()
			var hit_point = player_raycast.get_collision_point()
			print("   Collider: ", collider.name if collider else "null")
			print("   Collider type: ", collider.get_class() if collider else "null")
			print("   Collider groups: ", collider.get_groups() if collider else "null")
			print("   Hit point: ", hit_point)
			print("   Distance: ", player_raycast.get_collision_point().distance_to(player_raycast.global_position))
	
	# Check what the player is looking at
	if player_raycast.is_colliding():
		var collider = player_raycast.get_collider()
		var hit_point = player_raycast.get_collision_point()
		
		# DEBUG: Print when hitting something
		print("\n🎯 RAYCAST HIT: ", collider.name)
		print("   Type: ", collider.get_class())
		print("   Groups: ", collider.get_groups())
		print("   Hit point: ", hit_point)
		
		# Check if collider is a fingerprint surface
		if collider and collider.is_in_group("fingerprint_surface"):
			print("   ✅ This IS a fingerprint surface!")
			
			if current_detected_fingerprint != collider:
				print("   🆕 New fingerprint detected!")
				if current_detected_fingerprint and current_detected_fingerprint.has_method("reset_glow"):
					current_detected_fingerprint.reset_glow()
				
				current_detected_fingerprint = collider
				
				if collider.has_method("on_blue_light_detected"):
					print("   🔵 Calling on_blue_light_detected() on: ", collider.name)
					collider.on_blue_light_detected()
				else:
					print("   ⚠️ Fingerprint missing on_blue_light_detected method!")
		else:
			print("   ❌ NOT a fingerprint surface")
			print("   Expected group 'fingerprint_surface', got: ", collider.get_groups())
	else:
		# Not looking at anything
		if current_detected_fingerprint:
			print("🎯 Raycast lost target - resetting glow")
			if current_detected_fingerprint.has_method("reset_glow"):
				current_detected_fingerprint.reset_glow()
			current_detected_fingerprint = null

# Proximity detection (when player walks into fingerprint area)
func _on_body_entered(body: Node3D):
	print("\n🔵 BODY ENTERED (proximity): ", body.name)
	print("   Body type: ", body.get_class())
	print("   Body groups: ", body.get_groups())
	
	if not is_on:
		print("   Light off - ignoring")
		return
	
	var glasses_on = glasses_overlay and glasses_overlay.is_on if glasses_overlay else false
	if not glasses_on:
		print("   👓 Glasses off - fingerprint invisible")
		return
	
	if body.is_in_group("fingerprint_surface") and body.has_method("on_blue_light_detected"):
		print("   ✅ Fingerprint detected via proximity!")
		body.on_blue_light_detected()
		current_detected_fingerprint = body

func _on_body_exited(body: Node3D):
	print("\n🔵 BODY EXITED: ", body.name)
	if body.has_method("reset_glow"):
		body.reset_glow()
	
	if current_detected_fingerprint == body:
		current_detected_fingerprint = null

func reset_all_evidence():
	print("🔄 Resetting all fingerprint evidence")
	for body in get_overlapping_bodies():
		if body.has_method("reset_glow"):
			body.reset_glow()
	if current_detected_fingerprint:
		current_detected_fingerprint.reset_glow()
		current_detected_fingerprint = null
