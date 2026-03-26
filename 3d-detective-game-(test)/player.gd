# player.gd - With footstep sounds
extends CharacterBody3D

@export var walk_speed := 5.0
@export var sprint_speed := 8.0
@export var jump_velocity := 4.5
@export var mouse_sensitivity := 0.002
@export var gravity := 9.8
@export var hand_rotation_speed: float = 10.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var hand: Node3D = $Hand
@onready var interaction_ray: RayCast3D = $Head/Camera3D/InteractionRay

@onready var case_board: Control = get_tree().root.find_child("CaseBoard", true, false)

# Forensic tools
@onready var uv_light_system: Area3D = $Hand/UVLightDetectionArea
@onready var blue_light: Area3D = $Hand/BlueLightDetectionArea
@onready var magnifier_tool: Node3D = $Hand/MagnifierTool
@onready var glasses_overlay = get_node("/root/World/CanvasLayer/OrangeGlassesOverlay")

@export var interaction_ui: CanvasLayer

# Ray hit visual marker
var hit_glow_marker: MeshInstance3D = null

# ============================================================
# FOOTSTEP SOUND VARIABLES
# ============================================================
var footstep_timer: float = 0.0
var footstep_interval: float = 0.45  # Time between footsteps
# ============================================================

enum ForensicTool { NONE, UV, BLUE, MAGNIFIER }
var current_tool: ForensicTool = ForensicTool.NONE
var current_interactable: Node = null
var current_speed: float

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	current_speed = walk_speed
	interaction_ray.debug_shape_custom_color = Color.RED
	interaction_ray.debug_shape_thickness = 2
	
	# Create red glow marker for ray hit
	hit_glow_marker = MeshInstance3D.new()
	hit_glow_marker.mesh = SphereMesh.new()
	hit_glow_marker.scale = Vector3(0.08, 0.08, 0.08)
	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(1, 0, 0, 0.8)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color.RED
	hit_glow_marker.material_override = glow_mat
	add_child(hit_glow_marker)
	hit_glow_marker.visible = false
	
	# Initialize forensic tools
	if uv_light_system and uv_light_system.has_method("set_active"):
		uv_light_system.set_active(false)
	if blue_light and blue_light.has_method("set_active"):
		blue_light.set_active(false)
	if magnifier_tool and magnifier_tool.has_method("set_active"):
		magnifier_tool.set_active(false)
	print("🔧 Forensic tools ready - 1:UV, 2:Blue, 3:Magnifier, 0:None, G:Glasses")
	
	# Register camera for magnifier
	MagnifierManager.register_player_camera(camera)
	
	# DEBUG: Print raycast mask layers
	print("🔍 RAYCAST DEBUG:")
	print("   Raycast collision mask: ", interaction_ray.collision_mask)
	var masks = []
	for i in range(1, 33):
		if interaction_ray.get_collision_mask_value(i):
			masks.append(str(i))
	print("   Active mask layers: ", "Layer " + ", Layer ".join(masks))
	
	print("🔍 CaseBoard found: ", case_board)
	if case_board:
		print("   Path: ", case_board.get_path())
	else:
		print("   ❌ CaseBoard not found - check node name!")

func _input(event):
	# Mouse look
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -1.4, 1.4)
	
	# ESC key
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Left click to collect evidence
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if current_interactable:
			print("🖱️ Left click on: ", current_interactable.name)
			print("   Calling interact() on: ", current_interactable.name)
			CursorManager.set_cursor(CursorManager.CursorState.CLICK)
			current_interactable.interact()
			await get_tree().create_timer(0.1).timeout
			if current_interactable:
				CursorManager.set_cursor(CursorManager.CursorState.HOVER)
			else:
				CursorManager.reset_cursor()
	
	# Tool selection
	if event.is_action_pressed("tool_uv"):
		set_tool(ForensicTool.UV)
	elif event.is_action_pressed("tool_blue"):
		set_tool(ForensicTool.BLUE)
	elif event.is_action_pressed("tool_magnifier"):
		set_tool(ForensicTool.MAGNIFIER)
	elif event.is_action_pressed("tool_none"):
		set_tool(ForensicTool.NONE)
	
	# Toggle orange glasses
	if event.is_action_pressed("toggle_glasses"):
		if glasses_overlay and glasses_overlay.has_method("toggle"):
			glasses_overlay.toggle()
			SoundManager.play_glasses_on()
			
	if event.is_action_pressed("open_case_board"):
		print("🔑 C key pressed - toggling case board")
		print("   case_board node: ", case_board)
		if case_board:
			case_board.visible = !case_board.visible
			if case_board.visible:
				SoundManager.play_case_board_open()
			else:
				SoundManager.play_case_board_close()
			print("   case_board visible: ", case_board.visible)
		else:
			print("   ❌ case_board is null!")

func set_tool(tool: ForensicTool):
	# Turn off previous light
	match current_tool:
		ForensicTool.UV:
			if uv_light_system and uv_light_system.has_method("set_active"):
				uv_light_system.set_active(false)
				SoundManager.play_uv_off()
		ForensicTool.BLUE:
			if blue_light and blue_light.has_method("set_active"):
				blue_light.set_active(false)
				SoundManager.play_blue_off()
	
	current_tool = tool
	
	match tool:
		ForensicTool.UV:
			if uv_light_system and uv_light_system.has_method("set_active"):
				uv_light_system.set_active(true)
				SoundManager.play_uv_on()
			print("🔦 UV Light selected")
		ForensicTool.BLUE:
			if blue_light and blue_light.has_method("set_active"):
				blue_light.set_active(true)
				SoundManager.play_blue_on()
			print("🔵 Blue Light selected")
		ForensicTool.MAGNIFIER:
			if magnifier_tool and magnifier_tool.has_method("set_active"):
				magnifier_tool.set_active(true)
			print("🔍 Magnifier selected")
		ForensicTool.NONE:
			if magnifier_tool and magnifier_tool.has_method("set_active"):
				magnifier_tool.set_active(false)
			print("🔧 No tool selected")

func _physics_process(delta):
	# Sprint
	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed
	else:
		current_speed = walk_speed

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Movement
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var player_basis = Basis()
	player_basis = player_basis.rotated(Vector3.UP, rotation.y)
	var direction = (player_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	move_and_slide()
	
	# ============================================================
	# FOOTSTEP SOUNDS - Play when moving on ground
	# ============================================================
	if direction.length() > 0.1 and is_on_floor():
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			SoundManager.play_footstep()
			footstep_timer = footstep_interval
	else:
		footstep_timer = 0.0
	# ============================================================
	
func _process(delta):
	check_interaction()
	rotate_hand_toward_camera(delta)

func rotate_hand_toward_camera(delta):
	var target_x_rotation = camera.rotation.x
	hand.rotation.x = lerp(hand.rotation.x, target_x_rotation, hand_rotation_speed * delta)

func check_interaction():
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		var hit_point = interaction_ray.get_collision_point()
		
		# Show red marker at hit point
		if hit_glow_marker:
			hit_glow_marker.global_position = hit_point
			hit_glow_marker.visible = true
		
		if collider and collider.has_method("get_interaction_text"):
			CursorManager.set_cursor(CursorManager.CursorState.HOVER)
			
			if current_interactable != collider:
				if current_interactable and current_interactable.has_method("on_unfocus"):
					current_interactable.on_unfocus()
				
				current_interactable = collider
				if current_interactable.has_method("on_focus"):
					current_interactable.on_focus()
				
				if interaction_ui and interaction_ui.has_method("show_prompt"):
					interaction_ui.show_prompt(collider.get_interaction_text())
			return
	else:
		if hit_glow_marker:
			hit_glow_marker.visible = false
	
	if current_interactable:
		if current_interactable.has_method("on_unfocus"):
			current_interactable.on_unfocus()
		current_interactable = null
	
	if interaction_ui and interaction_ui.has_method("hide_prompt"):
		interaction_ui.hide_prompt()
	
	CursorManager.reset_cursor()
