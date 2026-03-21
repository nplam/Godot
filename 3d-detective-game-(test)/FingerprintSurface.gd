# FingerprintSurface.gd - With subtle glow that preserves texture
extends Area3D

@export var print_name: String = "Fingerprint"
@export var evidence_id: String = "fp_1"
@export var evidence_description: String = "A latent fingerprint that glows under blue light."
@export var glow_color: Color = Color(1.0, 0.5, 0.0)  # Orange glow
@export var glow_intensity: float = 0.8  # Lower intensity for subtle glow

# References - make sure these paths are correct
@onready var mesh_instance: MeshInstance3D = $HiddenFingerprint
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

# State tracking
var is_glowing: bool = false
var original_material: Material
var is_collected: bool = false

func _ready():
	# Debug initial state
	print("\n=== FINGERPRINT READY ===")
	print("Name: ", print_name)
	print("Node: ", name)
	print("Path: ", get_path())
	
	# Add to group for detection
	add_to_group("fingerprint_surface")
	print("Groups after adding: ", get_groups())
	
	# Set collision layer for blue light detection
	collision_layer = 5  # Fingerprint layer
	# Force layer bits
	set_collision_layer_value(5, true)
	set_collision_layer_value(3, false)
	print("Collision Layer set to: ", collision_layer)
	
	# Verify layer bits
	var layers = []
	for i in range(1, 6):
		if get_collision_layer_value(i):
			layers.append(str(i))
	print("Active Layers: ", "Layer " + ", Layer ".join(layers) if layers else "None")
	
	# Store original material and start invisible
	if mesh_instance:
		original_material = mesh_instance.material_override
		mesh_instance.visible = false
		print("✅ Mesh instance found: ", mesh_instance.name)
		print("   Mesh visible: ", mesh_instance.visible)
	else:
		print("❌ No MeshInstance3D found in fingerprint!")
		# Try to find it by name as fallback
		mesh_instance = find_child("MeshInstance3D", true, false)
		if mesh_instance:
			print("   ✅ Found via find_child!")
			original_material = mesh_instance.material_override
			mesh_instance.visible = false
		else:
			print("   ❌ Still not found - check node structure!")
	
	# Check collision shape
	if collision_shape:
		print("✅ CollisionShape3D found")
		print("   Position: ", collision_shape.position)
		print("   Scale: ", collision_shape.scale)
		print("   Disabled: ", collision_shape.disabled)
		if collision_shape.shape:
			print("   Shape type: ", collision_shape.shape.get_class())
			if collision_shape.shape is BoxShape3D:
				print("   Shape size: ", collision_shape.shape.size)
		else:
			print("   ⚠️ No shape assigned!")
	else:
		print("❌ No CollisionShape3D found!")
		# Try to find it as fallback
		collision_shape = find_child("CollisionShape3D", true, false)
		if collision_shape:
			print("   ✅ Found via find_child!")
	
	print("=== END FINGERPRINT READY ===\n")

# Called by blue light when detected
func on_blue_light_detected():
	print("\n🔵 on_blue_light_detected() CALLED for: ", print_name)
	print("   is_collected: ", is_collected)
	print("   is_glowing: ", is_glowing)
	
	if is_collected or is_glowing:
		print("   Already glowing or collected - ignoring")
		return
	
	if not mesh_instance:
		print("   ❌ No mesh instance - cannot show fingerprint!")
		return
	
	is_glowing = true
	print("🔵 Fingerprint REVEALED: ", print_name)
	
	# Make visible
	mesh_instance.visible = true
	print("   Mesh visibility set to: ", mesh_instance.visible)
	
	# Get current material (with your fingerprint texture)
	var current_mat = mesh_instance.material_override
	
	# If no material, create one
	if not current_mat:
		current_mat = StandardMaterial3D.new()
		mesh_instance.material_override = current_mat
	
	# Preserve the original texture if available
	if original_material and original_material.albedo_texture:
		current_mat.albedo_texture = original_material.albedo_texture
	
	# Add subtle orange glow to the existing material (preserves texture!)
	current_mat.emission_enabled = true
	current_mat.emission = glow_color
	current_mat.emission_energy_multiplier = glow_intensity
	
	# Make sure the base color is white to show the texture properly
	current_mat.albedo_color = Color.WHITE
	
	print("   Subtle glow added to fingerprint material")
	
	# Optional: Add a subtle pulsing effect
	if mesh_instance:
		create_glow_animation()
	
	print("=== END on_blue_light_detected ===\n")

func create_glow_animation():
	if not mesh_instance:
		return
	
	var tween = create_tween()
	tween.set_loops()
	# Scale pulse - very subtle (1.02 instead of 1.1)
	tween.tween_property(mesh_instance, "scale", mesh_instance.scale * 1.02, 0.8)
	tween.tween_property(mesh_instance, "scale", mesh_instance.scale, 0.8)

# Called by player when interacting with glowing fingerprint
func collect_evidence():
	print("\n💰 collect_evidence() CALLED for: ", print_name)
	if is_collected:
		print("   Already collected - ignoring")
		return
	
	is_collected = true
	print("✅ Collecting fingerprint: ", print_name)
	
	var data = {
		"id": evidence_id,
		"name": print_name,
		"description": evidence_description
	}
	EvidenceSystem.collect_evidence(data)
	print("   Evidence system called with ID: ", evidence_id)
	
	queue_free()
	print("   Fingerprint removed from scene")
	print("=== END collect_evidence ===\n")

# Reset when blue light moves away
func reset_glow():
	print("\n🔄 reset_glow() CALLED for: ", print_name)
	if not is_glowing:
		print("   Not glowing - ignoring")
		return
	
	is_glowing = false
	print("🔵 Fingerprint hidden again: ", print_name)
	
	# Hide and restore original material
	if mesh_instance:
		mesh_instance.visible = false
		mesh_instance.material_override = original_material
		print("   Mesh hidden and material restored")
	else:
		print("   ⚠️ No mesh instance to hide!")
	
	# Stop any animations
	var tween = get_tree().create_tween()
	tween.kill()
	print("=== END reset_glow ===\n")
