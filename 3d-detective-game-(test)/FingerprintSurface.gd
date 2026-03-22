# FingerprintSurface.gd - With subtle glow and double-click case board
extends Area3D

@export var print_name: String = "Fingerprint"
@export var evidence_id: String = "fp_1"
@export var evidence_description: String = "A latent fingerprint that glows under blue light."
@export var glow_color: Color = Color(1.0, 0.5, 0.0)  # Orange glow
@export var glow_intensity: float = 0.8

# References
@onready var mesh_instance: MeshInstance3D = $HiddenFingerprint
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

# State tracking
var is_glowing: bool = false
var original_material: Material
var is_collected: bool = false
var is_added_to_case: bool = false  # Track if already added to case board

func _ready():
	print("\n=== FINGERPRINT READY ===")
	print("Name: ", print_name)
	print("Node: ", name)
	print("Path: ", get_path())
	
	add_to_group("fingerprint_surface")
	print("Groups after adding: ", get_groups())
	
	collision_layer = 5
	set_collision_layer_value(5, true)
	set_collision_layer_value(3, false)
	print("Collision Layer set to: ", collision_layer)
	
	var layers = []
	for i in range(1, 6):
		if get_collision_layer_value(i):
			layers.append(str(i))
	print("Active Layers: ", "Layer " + ", Layer ".join(layers) if layers else "None")
	
	if mesh_instance:
		original_material = mesh_instance.material_override
		mesh_instance.visible = false
		print("✅ Mesh instance found: ", mesh_instance.name)
		print("   Mesh visible: ", mesh_instance.visible)
	else:
		print("❌ No MeshInstance3D found in fingerprint!")
		mesh_instance = find_child("MeshInstance3D", true, false)
		if mesh_instance:
			print("   ✅ Found via find_child!")
			original_material = mesh_instance.material_override
			mesh_instance.visible = false
		else:
			print("   ❌ Still not found - check node structure!")
	
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
		print("❌ No CollisionShape3D found!")
		collision_shape = find_child("CollisionShape3D", true, false)
		if collision_shape:
			print("   ✅ Found via find_child!")
	
	print("=== END FINGERPRINT READY ===\n")

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
	
	mesh_instance.visible = true
	print("   Mesh visibility set to: ", mesh_instance.visible)
	
	var current_mat = mesh_instance.material_override
	if not current_mat:
		current_mat = StandardMaterial3D.new()
		mesh_instance.material_override = current_mat
	
	if original_material and original_material.albedo_texture:
		current_mat.albedo_texture = original_material.albedo_texture
	
	current_mat.emission_enabled = true
	current_mat.emission = glow_color
	current_mat.emission_energy_multiplier = glow_intensity
	current_mat.albedo_color = Color.WHITE
	
	print("   Subtle glow added to fingerprint material")
	
	if mesh_instance:
		create_glow_animation()
	
	print("=== END on_blue_light_detected ===\n")

func create_glow_animation():
	if not mesh_instance:
		return
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(mesh_instance, "scale", mesh_instance.scale * 1.02, 0.8)
	tween.tween_property(mesh_instance, "scale", mesh_instance.scale, 0.8)

# NEW: Double-click to add to case board (does NOT remove evidence)
func add_to_case_board():
	if is_added_to_case or is_collected:
		print("   Already added or collected - ignoring")
		return
	
	is_added_to_case = true
	print("📋 Double-clicked! Adding to case board: ", print_name)
	
	var data = {
		"id": evidence_id,
		"name": print_name,
		"description": evidence_description
	}
	
	var case_board = get_tree().get_first_node_in_group("case_board")
	if case_board and case_board.has_method("add_evidence"):
		case_board.add_evidence(data)
		flash_orange()  # Visual feedback
		print("   ✅ Added to case board")
	else:
		print("   ⚠️ Case board not found!")

# Visual feedback when added to case board
func flash_orange():
	if mesh_instance:
		var original_mat = mesh_instance.material_override
		var flash_mat = StandardMaterial3D.new()
		flash_mat.albedo_color = Color(1, 0.8, 0)  # Bright orange
		flash_mat.emission_enabled = true
		flash_mat.emission = Color(1, 0.5, 0)
		mesh_instance.material_override = flash_mat
		await get_tree().create_timer(0.2).timeout
		mesh_instance.material_override = original_mat

# Left-click to collect (removes from world, adds to inventory)
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

# Input event for double-click detection
func _input_event(camera: Camera3D, event: InputEvent, position: Vector3, normal: Vector3, shape_idx: int):
	# Only respond if glowing and not collected
	if is_glowing and not is_collected and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click:
				# Double-click: add to case board
				add_to_case_board()
			else:
				# Single click: collect evidence
				collect_evidence()

func reset_glow():
	print("\n🔄 reset_glow() CALLED for: ", print_name)
	if not is_glowing:
		print("   Not glowing - ignoring")
		return
	
	is_glowing = false
	print("🔵 Fingerprint hidden again: ", print_name)
	
	if mesh_instance:
		mesh_instance.visible = false
		mesh_instance.material_override = original_material
		print("   Mesh hidden and material restored")
	else:
		print("   ⚠️ No mesh instance to hide!")
	
	var tween = get_tree().create_tween()
	tween.kill()
	print("=== END reset_glow ===\n")
