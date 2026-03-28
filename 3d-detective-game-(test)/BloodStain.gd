# Shoeprint.gd - Updated with complete evidence data for CaseBoard
extends StaticBody3D

@export var stain_name: String = "Shoeprint"
@export var stain_description: String = "A muddy shoeprint that glows under UV light."
@export var evidence_id: String = "shoe_1"
@export var evidence_type: int = 0  # 0 = SHOEPRINT
@export var match_value: String = "loafers"  # Matches suspect's shoe_type
@export var glow_color: Color = Color(0, 1, 0)  # Green glow
@export var glow_intensity: float = 3.0
@export var evidence_texture: Texture2D

# References
@onready var mesh_instance: MeshInstance3D = $HiddenBloodStain
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

# State tracking
var is_glowing: bool = false
var original_material: Material
var is_added_to_case: bool = false

# Double-click detection
var last_click_time: float = 0
var double_click_threshold: float = 0.3  # 0.3 seconds between clicks

func _ready():
	print("\n========== SHOEPRINT READY ==========")
	print("📍 POSITION: ", global_position)
	print("🆔 Evidence ID: ", evidence_id)
	print("🔢 Evidence Type: ", evidence_type, " (SHOEPRINT)")
	print("🎯 Match Value: ", match_value)
	
	# Set collision layer (Layer 4)
	collision_layer = 4
	set_collision_layer_value(3, false)
	set_collision_layer_value(4, true)
	
	# Enable input detection
	input_ray_pickable = true
	print("   Input ray pickable: ", input_ray_pickable)
	
	# Add to groups
	add_to_group("blood_stain")
	add_to_group("shoeprint")
	print("👥 GROUPS: ", get_groups())
	
	# Store original material and start invisible
	if mesh_instance:
		original_material = mesh_instance.material_override
		mesh_instance.visible = false
	
	print("👣 Shoeprint ready - UV light to reveal, double-click to add to case board")

func get_interaction_text() -> String:
	return "Examine " + stain_name

# Called by Player.gd when clicking
func interact():
	print("🖱️ interact() called on shoeprint")
	print("   is_glowing: ", is_glowing)
	print("   is_added_to_case: ", is_added_to_case)
	
	if is_glowing and not is_added_to_case:
		var current_time = Time.get_ticks_msec() / 1000.0
		var time_diff = current_time - last_click_time
		
		print("   Time since last click: ", time_diff)
		
		if time_diff < double_click_threshold and time_diff > 0.01:
			print("\n📋📋📋 DOUBLE CLICK DETECTED! Adding to case board 📋📋📋")
			add_to_case_board()
		else:
			print("   Single click detected (double-click within ", double_click_threshold, "s to add)")
		
		last_click_time = current_time

func on_uv_detected():
	print("\n🔆 UV DETECTED! Shoeprint at ", global_position)
	
	if is_added_to_case or is_glowing:
		return
	
	is_glowing = true
	print("✨ Shoeprint REVEALED! (Green glow)")
	
	if mesh_instance:
		mesh_instance.visible = true
		
		var current_mat = mesh_instance.material_override
		if not current_mat:
			current_mat = StandardMaterial3D.new()
			mesh_instance.material_override = current_mat
		
		current_mat.emission_enabled = true
		current_mat.emission = glow_color
		current_mat.emission_energy_multiplier = glow_intensity

func add_to_case_board():
	print("\n📋 add_to_case_board() CALLED")
	print("   stain_name: ", stain_name)
	print("   evidence_id: ", evidence_id)
	print("   evidence_type: ", evidence_type)
	print("   match_value: ", match_value)
	print("   is_added_to_case: ", is_added_to_case)
	
	if is_added_to_case:
		print("   Already added to case board - ignoring")
		return
	
	is_added_to_case = true
	print("📋 Adding to case board: ", stain_name)
	
	# Complete evidence data for CaseBoard
	var data = {
		"id": evidence_id,
		"name": stain_name,
		"description": stain_description,
		"texture": evidence_texture,
		"type": evidence_type,  # 0 = SHOEPRINT
		"match_value": match_value  # e.g., "loafers", "work boots", etc.
	}
	
	var case_board = get_tree().get_first_node_in_group("case_board")
	print("   case_board found: ", case_board)
	
	if case_board and case_board.has_method("add_evidence"):
		case_board.add_evidence(data)
		SoundManager.play_evidence_collect()
		print("   ✅ Added to case board!")
		
		# Visual feedback - flash green to confirm
		if mesh_instance:
			var flash_mat = StandardMaterial3D.new()
			flash_mat.albedo_color = Color(0, 1, 0)
			flash_mat.emission_enabled = true
			flash_mat.emission = Color(0, 1, 0)
			mesh_instance.material_override = flash_mat
			await get_tree().create_timer(0.2).timeout
			mesh_instance.material_override = original_material
	else:
		print("   ⚠️ Case board not found or missing add_evidence method")

func reset_glow():
	if not is_glowing:
		return
	is_glowing = false
	print("👣 Shoeprint hidden (glow removed)")
	
	if mesh_instance:
		mesh_instance.visible = false
		mesh_instance.material_override = original_material
