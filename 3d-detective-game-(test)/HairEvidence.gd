# HairEvidence.gd - With collision debug
extends StaticBody3D

@export var hair_name: String = "Red Hair Strand"
@export var evidence_id: String = "hair_2"
@export var evidence_type: int = 2
@export var match_value: String = "Red"
@export var evidence_description: String = "A red hair strand found on the floor."
@export var evidence_texture: Texture2D

@onready var hair_sprite: Sprite3D = $HairSprite
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var is_collected: bool = false
var is_added_to_case: bool = false
var last_click_time: float = 0.0

func _ready():
	print("\n" + "=".repeat(50))
	print("🔴 RED HAIR DEBUG")
	print("=".repeat(50))
	
	# Add to groups
	add_to_group("hair_evidence")
	add_to_group("evidence")
	print("📌 Groups: ", get_groups())
	
	# Make it clickable
	input_ray_pickable = true
	print("🎯 input_ray_pickable: ", input_ray_pickable)
	
	# Set collision layers
	collision_layer = 3
	set_collision_layer_value(3, true)
	set_collision_layer_value(1, true)
	print("🔲 Collision layer: ", collision_layer)
	print("   Layer 1 enabled: ", get_collision_layer_value(1))
	print("   Layer 3 enabled: ", get_collision_layer_value(3))
	
	# COLLISION SHAPE DEBUG
	print("\n🔲 COLLISION SHAPE:")
	if collision_shape:
		print("   ✅ Found: ", collision_shape.name)
		print("   Position: ", collision_shape.position)
		print("   Scale: ", collision_shape.scale)
		print("   Disabled: ", collision_shape.disabled)
		
		if collision_shape.shape:
			print("   Shape type: ", collision_shape.shape.get_class())
			if collision_shape.shape is BoxShape3D:
				var box = collision_shape.shape as BoxShape3D
				print("   Box size: ", box.size)
				print("   Box extents: ", box.size / 2)
			elif collision_shape.shape is SphereShape3D:
				var sphere = collision_shape.shape as SphereShape3D
				print("   Sphere radius: ", sphere.radius)
		else:
			print("   ❌ No shape assigned!")
			
		# Calculate world bounds
		var global_pos = global_position + collision_shape.position
		var half_size = Vector3(0.05, 0.03, 0.05)  # Default half size
		if collision_shape.shape and collision_shape.shape is BoxShape3D:
			half_size = (collision_shape.shape as BoxShape3D).size / 2
		
		print("\n📍 COLLISION BOUNDS:")
		print("   Center: ", global_pos)
		print("   Min: ", global_pos - half_size)
		print("   Max: ", global_pos + half_size)
		print("   Y range: ", global_pos.y - half_size.y, " to ", global_pos.y + half_size.y)
	else:
		print("   ❌ No CollisionShape3D found!")
	
	# SPRITE DEBUG
	print("\n🖼️ SPRITE:")
	if hair_sprite:
		print("   ✅ Found: ", hair_sprite.name)
		print("   Position: ", hair_sprite.position)
		print("   Scale: ", hair_sprite.scale)
		hair_sprite.visible = true
	else:
		print("   ❌ No HairSprite found!")
	
	# POSITION DEBUG
	print("\n📍 POSITION:")
	print("   Global position: ", global_position)
	print("   Local position: ", position)
	print("   Y level: ", global_position.y)
	
	# Suggest fixes
	if global_position.y < 0.01:
		print("\n⚠️ WARNING: Hair is below ground level (Y = ", global_position.y, ")")
		print("   Move it up so Y is between 0.02 and 0.05")
	
	if collision_shape and collision_shape.shape:
		var box_size = (collision_shape.shape as BoxShape3D).size if collision_shape.shape is BoxShape3D else Vector3(0.1, 0.05, 0.1)
		if box_size.y < 0.05:
			print("\n⚠️ WARNING: Collision shape height is very small (", box_size.y, ")")
			print("   Increase Y size to at least 0.05")
	
	print("=".repeat(50) + "\n")

func get_interaction_text() -> String:
	return "Examine " + hair_name

func interact():
	print("\n🖱️ INTERACT called on red hair")
	
	if is_collected:
		print("   Already collected!")
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_diff = current_time - last_click_time if last_click_time > 0 else 999
	
	if time_diff < 0.3 and time_diff > 0.01:
		print("   DOUBLE CLICK! Adding to case board")
		add_to_case_board()
	else:
		print("   Single click - double-click within 0.3s to add")
	
	last_click_time = current_time

func add_to_case_board():
	if is_added_to_case or is_collected:
		return
	
	is_added_to_case = true
	print("📋 Adding red hair to case board")
	
	var data = {
		"id": evidence_id,
		"name": hair_name,
		"description": evidence_description,
		"texture": evidence_texture,
		"type": evidence_type,
		"match_value": match_value
	}
	
	var case_board = get_tree().get_first_node_in_group("case_board")
	if case_board and case_board.has_method("add_evidence"):
		case_board.add_evidence(data)
		
		if hair_sprite:
			hair_sprite.modulate = Color(1, 1, 0.5)
			await get_tree().create_timer(0.2).timeout
			hair_sprite.modulate = Color(1, 1, 1)
		
		queue_free()
		print("   ✅ Added to case board")
	else:
		print("   ⚠️ Case board not found!")
