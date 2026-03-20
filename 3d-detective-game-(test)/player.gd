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

# Forensic tools
@onready var uv_light_system: Area3D = $Hand/UVLightDetectionArea
@onready var blue_light: Area3D = $Hand/BlueLightDetectionArea
@onready var magnifier_tool: Node3D = $Hand/MagnifierTool  # NEW: Magnifier tool
@onready var glasses_overlay = get_node("/root/World/CanvasLayer/OrangeGlassesOverlay")

@export var interaction_ui: CanvasLayer

# Updated enum to include MAGNIFIER
enum ForensicTool { NONE, UV, BLUE, MAGNIFIER }
var current_tool: ForensicTool = ForensicTool.NONE
var current_interactable: Node = null
var current_speed: float

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	current_speed = walk_speed
	interaction_ray.debug_shape_custom_color = Color.RED
	interaction_ray.debug_shape_thickness = 2
	
	# Verify forensic tools are ready
	if uv_light_system and uv_light_system.has_method("set_active"):
		uv_light_system.set_active(false)
	if blue_light and blue_light.has_method("set_active"):
		blue_light.set_active(false)
	if magnifier_tool and magnifier_tool.has_method("set_active"):  # NEW
		magnifier_tool.set_active(false)
	print("🔧 Forensic tools ready - 1:UV, 2:Blue, 3:Magnifier, 0:None, G:Glasses")  # Updated
	
	# Debug glasses overlay
	if glasses_overlay:
		print("✅ Glasses overlay found: ", glasses_overlay)
	else:
		print("❌ Glasses overlay NOT found - check path!")
		
	# Verify toggle_glasses action
	print("🔍 Input Map has toggle_glasses: ", InputMap.has_action("toggle_glasses"))

	# Register this player's camera with the magnifier system
	MagnifierManager.register_player_camera(camera)
	print("📷 Player camera registered with magnifier system")
	
func _input(event):
	# MOUSE LOOK
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
	
	# LEFT CLICK to interact
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if current_interactable:
			print("🖱️ Left click on: ", current_interactable.name)
			CursorManager.set_cursor(CursorManager.CursorState.CLICK)
			current_interactable.interact()
			await get_tree().create_timer(0.1).timeout
			if current_interactable:
				CursorManager.set_cursor(CursorManager.CursorState.HOVER)
			else:
				CursorManager.reset_cursor()
	
	# Forensic tool selection - UPDATED to include magnifier
	if event.is_action_pressed("tool_uv"):
		set_tool(ForensicTool.UV)
	elif event.is_action_pressed("tool_blue"):
		set_tool(ForensicTool.BLUE)
	elif event.is_action_pressed("tool_magnifier"):  # NEW
		set_tool(ForensicTool.MAGNIFIER)
	elif event.is_action_pressed("tool_none"):
		set_tool(ForensicTool.NONE)
	
	# Toggle orange glasses
	if event.is_action_pressed("toggle_glasses"):
		print("👓 toggle_glasses action detected!")
		if glasses_overlay and glasses_overlay.has_method("toggle"):
			print("   Glasses overlay exists, toggling...")
			glasses_overlay.toggle()
		else:
			print("   ❌ glasses_overlay is null or missing toggle method!")

func set_tool(tool: ForensicTool):
	# Only turn off the previous light, NOT the magnifier
	match current_tool:
		ForensicTool.UV:
			if uv_light_system and uv_light_system.has_method("set_active"):
				uv_light_system.set_active(false)
		ForensicTool.BLUE:
			if blue_light and blue_light.has_method("set_active"):
				blue_light.set_active(false)
		# MAGNIFIER doesn't need deactivation here
	
	current_tool = tool
	
	match tool:
		ForensicTool.UV:
			if uv_light_system and uv_light_system.has_method("set_active"):
				uv_light_system.set_active(true)
			print("🔦 UV Light selected - detects blood stains and shoeprints")
		ForensicTool.BLUE:
			if blue_light and blue_light.has_method("set_active"):
				blue_light.set_active(true)
			print("🔵 Blue Light selected - detects fingerprints (requires orange glasses)")
		ForensicTool.MAGNIFIER:
			if magnifier_tool and magnifier_tool.has_method("set_active"):
				magnifier_tool.set_active(true)
			print("🔍 Magnifier selected - zoom in on details")
		ForensicTool.NONE:
			# Turn off everything including magnifier
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
	
func _process(delta):
	check_interaction()
	rotate_hand_toward_camera(delta)

func rotate_hand_toward_camera(delta):
	var target_x_rotation = camera.rotation.x
	hand.rotation.x = lerp(hand.rotation.x, target_x_rotation, hand_rotation_speed * delta)

func check_interaction():
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		
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
	
	if current_interactable:
		if current_interactable.has_method("on_unfocus"):
			current_interactable.on_unfocus()
		current_interactable = null
	
	if interaction_ui and interaction_ui.has_method("hide_prompt"):
		interaction_ui.hide_prompt()
	
	CursorManager.reset_cursor()
