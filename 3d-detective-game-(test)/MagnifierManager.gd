# MagnifierManager.gd - Cursor-aligned magnifier
extends Node

var magnifier_ui = null
var player_camera = null
var magnifier_viewport = null
var magnifier_cam = null

# Smoothing for cursor movement
var smoothed_dir: Vector3 = Vector3.ZERO
var smoothing_factor: float = 0.3  # Lower = smoother, higher = more responsive

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
	
	# Reset smoothing when activating
	if active:
		smoothed_dir = Vector3.ZERO

func update_magnifier_position(mouse_pos: Vector2):
	if magnifier_ui and magnifier_ui.has_method("update_position"):
		magnifier_ui.update_position(mouse_pos)

func _process(delta):
	if magnifier_ui and magnifier_ui.is_active and player_camera and magnifier_cam:
		# Get current mouse position
		var mouse_pos = get_viewport().get_mouse_position()
		
		# Calculate ray from camera through mouse position
		var from = player_camera.project_ray_origin(mouse_pos)
		var dir = player_camera.project_ray_normal(mouse_pos)
		
		# Smooth the direction to prevent shaking
		if smoothed_dir == Vector3.ZERO:
			smoothed_dir = dir
		else:
			smoothed_dir = smoothed_dir.lerp(dir, smoothing_factor)
		
		# Position magnifier camera at player's eye
		magnifier_cam.global_position = player_camera.global_position
		
		# Make magnifier camera look at where mouse is pointing
		var look_at_pos = from + smoothed_dir * 10.0
		magnifier_cam.look_at(look_at_pos, Vector3.UP)
		
		# Small forward offset to better match perspective
		magnifier_cam.global_position += smoothed_dir * 0.2
