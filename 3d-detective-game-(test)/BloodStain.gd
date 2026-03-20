# BloodStain.gd - Updated for shoeprint with glow
extends Area3D

@export var stain_name: String = "Shoeprint"  # Changed from Blood Stain
@export var stain_description: String = "A muddy shoeprint that glows under UV light."  # Changed
@export var evidence_id: String = "shoe_1"  # Changed
@export var glow_color: Color = Color(0, 1, 0)  # Green glow (changed from red)
@export var glow_intensity: float = 3.0  # Slightly lower for shoeprint

# References
@onready var mesh_instance: MeshInstance3D = $HiddenBloodStain
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

# State tracking
var is_glowing: bool = false
var original_material: Material
var is_collected: bool = false

func _ready():
	# Debug initial state
	print("\n=== SHOEPRINT READY ===")
	print("Name: ", stain_name)
	print("Node: ", name)
	print("Path: ", get_path())
	
	# Add to group for detection
	add_to_group("shoeprint")  # Changed from blood_stain
	print("Groups after adding: ", get_groups())
	
	# Set collision layer for UV light detection
	collision_layer = 4  # UV evidence layer
	# Force layer bits
	set_collision_layer_value(4, true)
	set_collision_layer_value(3, false)  # Explicitly turn off layer 3
	print("Collision Layer set to: ", collision_layer)
	
	# Verify layer bits
	var layers = []
	for i in range(1, 6):
		if get_collision_layer_value(i):
			layers.append(str(i))
	print("Active Layers: ", "Layer " + ", Layer ".join(layers) if layers else "None")
	
	# Store original material (if any)
	if mesh_instance:
		original_material = mesh_instance.material_override
		# Start invisible
		mesh_instance.visible = false
		print("Mesh instance found: ", mesh_instance.name)
		print("Mesh visible: ", mesh_instance.visible)
	else:
		print("⚠️ No MeshInstance3D found in shoeprint")
	
	# Check collision shape
	if collision_shape:
		print("CollisionShape3D found")
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
		print("⚠️ No CollisionShape3D found!")
	
	print("=== END SHOEPRINT READY ===\n")

# Called by UV light when detected
func on_uv_detected():
	print("\n👣 on_uv_detected() CALLED for: ", stain_name)
	print("   is_collected: ", is_collected)
	print("   is_glowing: ", is_glowing)
	
	if is_collected or is_glowing:
		print("   Already glowing or collected - ignoring")
		return
	
	is_glowing = true
	print("👣 Shoeprint REVEALED: ", stain_name)
	
	# Make visible and add glow to existing material
	if mesh_instance:
		mesh_instance.visible = true
		
		# Get the current material (with your shoeprint texture)
		var current_mat = mesh_instance.material_override
		
		# If there's no material, create one
		if not current_mat:
			current_mat = StandardMaterial3D.new()
			mesh_instance.material_override = current_mat
		
		# Add green glow to the existing material (preserves texture!)
		current_mat.emission_enabled = true
		current_mat.emission = glow_color
		current_mat.emission_energy_multiplier = glow_intensity
		
		print("   Mesh visibility set to: ", mesh_instance.visible)
		print("   Glow added to existing shoeprint material")
	else:
		print("   ⚠️ No mesh instance to show!")
	
	# Optional: Add a subtle pulsing effect
	create_glow_animation()
	print("=== END on_uv_detected ===\n")

func create_glow_animation():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(mesh_instance, "scale", mesh_instance.scale * 1.05, 0.5)
	tween.tween_property(mesh_instance, "scale", mesh_instance.scale, 0.5)

# Called by player when interacting with glowing shoeprint
func collect_evidence():
	print("\n💰 collect_evidence() CALLED for: ", stain_name)
	if is_collected:
		print("   Already collected - ignoring")
		return
	
	is_collected = true
	print("✅ Collecting shoeprint: ", stain_name)
	
	# Pass a Dictionary to EvidenceSystem
	var data = {
		"id": evidence_id,
		"name": stain_name,
		"description": stain_description
	}
	EvidenceSystem.collect_evidence(data)
	print("   Evidence system called with ID: ", evidence_id)
	
	queue_free()
	print("   Shoeprint removed from scene")
	print("=== END collect_evidence ===\n")

# Reset when UV light moves away
func reset_glow():
	print("\n🔄 reset_glow() CALLED for: ", stain_name)
	if not is_glowing:
		print("   Not glowing - ignoring")
		return
	is_glowing = false
	print("👣 Shoeprint hidden again: ", stain_name)
	
	# Hide and restore original material
	if mesh_instance:
		mesh_instance.visible = false
		mesh_instance.material_override = original_material
		print("   Mesh hidden and material restored")
	
	# Stop any animations
	var tween = get_tree().create_tween()
	tween.kill()
	print("=== END reset_glow ===\n")
