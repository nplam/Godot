# MagnifierManager.gd - With adjustable speed and smoothing
extends Node

var magnifier_ui = null
var player_camera = null
var magnifier_viewport = null
var magnifier_cam = null

# Adjust these values to control speed
var mouse_sensitivity: float = 0.001  # Much slower (was 0.005)
var magnifier_yaw: float = 0.0
var magnifier_pitch: float = 0.0

# Smoothing variables
var target_yaw: float = 0.0
var target_pitch: float = 0.0
var smooth_speed: float = 10.0  # Higher = faster response

func register_magnifier_ui(ui_node):
	magnifier_ui = ui_node

func register_player_camera(camera_node):
	player_camera = camera_node

func register_magnifier_viewport(viewport_node):
	magnifier_viewport = viewport_node
	if magnifier_viewport:
		magnifier_cam = magnifier_viewport.get_node("MagnifierCamera")
		magnifier_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

func set_magnifier_active(active: bool):
	if magnifier_ui and magnifier_ui.has_method("set_active"):
		magnifier_ui.set_active(active)
	
	if active and player_camera:
		# Initialize magnifier camera to look where player is looking
		var player_basis = player_camera.global_transform.basis
		var player_euler = player_basis.get_euler()
		target_yaw = player_euler.y
		target_pitch = player_euler.x
		magnifier_yaw = target_yaw
		magnifier_pitch = target_pitch

func update_magnifier_position(mouse_pos: Vector2):
	if magnifier_ui and magnifier_ui.has_method("update_position"):
		magnifier_ui.update_position(mouse_pos)

func _process(delta):
	if magnifier_ui and magnifier_ui.is_active and magnifier_cam:
		# Get mouse movement (use relative motion instead of velocity)
		var mouse_motion = Input.get_last_mouse_velocity()
		
		# Update target rotation with much lower sensitivity
		target_yaw -= mouse_motion.x * mouse_sensitivity
		target_pitch -= mouse_motion.y * mouse_sensitivity
		target_pitch = clamp(target_pitch, -1.4, 1.4)  # Limit up/down
		
		# Smoothly interpolate to target rotation
		magnifier_yaw = lerp(magnifier_yaw, target_yaw, smooth_speed * delta)
		magnifier_pitch = lerp(magnifier_pitch, target_pitch, smooth_speed * delta)
		
		# Apply rotation to magnifier camera
		magnifier_cam.rotation = Vector3(magnifier_pitch, magnifier_yaw, 0)
		
		# Position at player's location
		if player_camera:
			magnifier_cam.global_position = player_camera.global_position
