extends Control

# Node references
@onready var main_panel: Control = $MainPanel
@onready var object_name_label: Label = $MainPanel/ObjectName
@onready var description_label: RichTextLabel = $MainPanel/Description
@onready var viewport_display: TextureRect = $MainPanel/ViewportDisplay
@onready var render_viewport: SubViewport = $MainPanel/RenderViewport
@onready var close_button: Button = $MainPanel/CloseButton
@onready var take_button: Button = $MainPanel/ButtonContainer/TakeEvidenceButton
@onready var cancel_button: Button = $MainPanel/ButtonContainer/CancelButton

# Variables
var current_interactable = null
var on_take_callback: Callable
var on_cancel_callback: Callable
var current_object_copy: Node3D = null  # Store the cloned object for rotation
var is_dragging: bool = false
var last_mouse_position: Vector2

func _ready():
	print("🔧 INSPECTION VIEW READY")
	
	# Connect buttons
	cancel_button.pressed.connect(_on_cancel)
	take_button.pressed.connect(_on_take)
	close_button.pressed.connect(_on_cancel)
	
	# Setup viewport
	render_viewport.world_3d = World3D.new()
	render_viewport.disable_3d = false
	render_viewport.transparent_bg = false
	render_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	render_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	
	hide()

func inspect(interactable, take_callback: Callable, cancel_callback: Callable):
	print("Inspect called for: ", interactable.object_name)
	
	current_interactable = interactable
	on_take_callback = take_callback
	on_cancel_callback = cancel_callback
	
	object_name_label.text = interactable.object_name
	description_label.text = "[b]" + interactable.object_name + "[/b]\n\n" + interactable.examination_text
	
	# Show cursor for UI interaction
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	CursorManager.set_cursor(CursorManager.CursorState.NORMAL)
	
	# Setup the 3D view
	await setup_viewport(interactable)
	
	show()

func setup_viewport(interactable):
	# Clear everything in viewport
	for child in render_viewport.get_children():
		child.queue_free()
	current_object_copy = null
	
	# Add camera
	var cam = Camera3D.new()
	cam.name = "InspectionCamera"
	cam.current = true
	cam.position = Vector3(0, 0, 3)
	render_viewport.add_child(cam)
	
	# Add main light
	var light = DirectionalLight3D.new()
	light.name = "InspectionLight"
	light.rotation = Vector3(-45, 45, 0)
	light.light_energy = 1.5
	render_viewport.add_child(light)
	
	# Add fill light
	var fill_light = DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.rotation = Vector3(45, -45, 0)
	fill_light.light_energy = 0.5
	render_viewport.add_child(fill_light)
	
	# Add the actual clue object
	var object_copy = interactable.duplicate()
	render_viewport.add_child(object_copy)
	current_object_copy = object_copy
	
	# Position it nicely
	object_copy.position = Vector3(0, 0, -2)
	object_copy.rotation = Vector3(0, 0, 0)
	
	# Auto-scale based on object size
	var mesh_instance = object_copy.find_child("*MeshInstance3D*", true, false)
	if mesh_instance and mesh_instance.mesh:
		var aabb = mesh_instance.mesh.get_aabb()
		var max_dimension = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
		var target_size = 2.0
		var scale_factor = target_size / max_dimension
		object_copy.scale = Vector3(scale_factor, scale_factor, scale_factor)
		print("   📏 Auto-scaled by factor: ", scale_factor)
	else:
		object_copy.scale = Vector3(2, 2, 2)  # Fallback
	
	# Make the camera look at the clue
	cam.look_at(object_copy.position, Vector3.UP)
	
	# Wait for first render
	await RenderingServer.frame_post_draw
	
	# Assign texture to display
	viewport_display.texture = render_viewport.get_texture()
	viewport_display.modulate = Color.WHITE
	
	print("✅ Clue object displayed: ", interactable.object_name)

func _input(event):
	if not visible or not current_object_copy:
		return
	
	# Check if mouse is over the viewport display area
	var mouse_pos = get_global_mouse_position()
	var viewport_rect = Rect2(viewport_display.global_position, viewport_display.size)
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and viewport_rect.has_point(mouse_pos):
				# Start dragging
				is_dragging = true
				last_mouse_position = mouse_pos
				print("🖱️ Drag started")
			elif not event.pressed:
				# Stop dragging
				is_dragging = false
				print("🖱️ Drag ended")
	
	elif event is InputEventMouseMotion and is_dragging:
		# Calculate delta movement
		var delta = mouse_pos - last_mouse_position
		last_mouse_position = mouse_pos
		
		# Rotate the object based on mouse movement
		# Horizontal movement rotates around Y axis (yaw)
		# Vertical movement rotates around X axis (pitch)
		var rotation_speed = 0.01
		current_object_copy.rotation.y -= delta.x * rotation_speed
		current_object_copy.rotation.x += delta.y * rotation_speed
		
		# Optional: clamp pitch to avoid flipping
		current_object_copy.rotation.x = clamp(current_object_copy.rotation.x, -1.0, 1.0)

func _on_take():
	print("Take button pressed")
	
	# Call the callback
	if on_take_callback.is_valid():
		on_take_callback.call()
	
	# Cleanup viewport
	for child in render_viewport.get_children():
		child.queue_free()
	current_object_copy = null
	viewport_display.texture = null
	
	# Restore mouse mode for gameplay
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	CursorManager.reset_cursor()
	
	hide()

func _on_cancel():
	print("Cancel button pressed")
	
	# Call the callback
	if on_cancel_callback.is_valid():
		on_cancel_callback.call()
	
	# Cleanup viewport
	for child in render_viewport.get_children():
		child.queue_free()
	current_object_copy = null
	viewport_display.texture = null
	
	# Restore mouse mode for gameplay
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	CursorManager.reset_cursor()
	
	hide()
