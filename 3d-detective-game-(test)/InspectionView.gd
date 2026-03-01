extends Control

# Node references
@onready var viewport_container: SubViewportContainer = $ViewportContainer
@onready var render_viewport: SubViewport = $ViewportContainer/RenderViewport
@onready var close_button: Button = $CloseButton
@onready var take_button: Button = $HBoxContainer/TakeEvidenceButton
@onready var cancel_button: Button = $HBoxContainer/CancelButton
@onready var object_name_label: Label = $ObjectName
@onready var description_label: RichTextLabel = $Description

# Variables
var current_interactable = null
var on_take_callback: Callable
var on_cancel_callback: Callable
var current_object: Node3D = null  # This will be the wrapper
var is_dragging: bool = false
var last_mouse_position: Vector2

# Manual offset adjustment - CHANGE THESE VALUES to center your object
var manual_offset_x = 0.0
var manual_offset_y = 0.0
var manual_offset_z = 0.0

func _ready():
	print("🔧 INSPECTION VIEW READY")
	print("   close_button: ", close_button)
	print("   take_button: ", take_button)
	print("   cancel_button: ", cancel_button)
	print("   viewport_container: ", viewport_container)
	print("   render_viewport: ", render_viewport)
	
	# Connect buttons with null checks
	if close_button:
		close_button.pressed.connect(_on_cancel)
		print("   ✅ Close button connected")
	else:
		print("   ❌ close_button is null!")
	
	if take_button:
		take_button.pressed.connect(_on_take)
		print("   ✅ Take button connected")
	else:
		print("   ❌ take_button is null!")
	
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel)
		print("   ✅ Cancel button connected")
	else:
		print("   ❌ cancel_button is null!")
	
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
	
	# Show cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Setup the 3D view
	await setup_viewport(interactable)
	
	show()

func setup_viewport(interactable):
	# Clear previous objects
	for child in render_viewport.get_children():
		if child is Camera3D or child is Light3D:
			continue
		child.queue_free()
	
	# Get camera reference
	var cam = render_viewport.get_node("InspectionCamera")
	if not cam:
		cam = Camera3D.new()
		cam.name = "InspectionCamera"
		cam.current = true
		cam.position = Vector3(0, 0, 3)
		render_viewport.add_child(cam)
	
	# Set viewport size to match container
	await get_tree().process_frame
	render_viewport.size = viewport_container.size
	print("   📺 Viewport size: ", render_viewport.size)
	
	# Create a wrapper node - this will be rotated
	var wrapper = Node3D.new()
	wrapper.name = "ObjectWrapper"
	render_viewport.add_child(wrapper)
	
	# Create object copy and add it to wrapper
	var object_copy = interactable.duplicate()
	wrapper.add_child(object_copy)
	current_object = wrapper  # Store wrapper for rotation
	
	# Reset all materials
	var meshes = object_copy.find_children("*", "MeshInstance3D", true, false)
	print("   Found ", meshes.size(), " meshes")
	
	for mesh in meshes:
		mesh.material_override = null
	
	# If no meshes, use fallback
	if meshes.size() == 0:
		wrapper.scale = Vector3(2, 2, 2)
		wrapper.position = Vector3(0, 0, -2)
		print("   ⚠️ No meshes found, using fallback")
		await RenderingServer.frame_post_draw
		return
	
	# Calculate the true visual bounds of the object
	var bounds_min = Vector3(INF, INF, INF)
	var bounds_max = Vector3(-INF, -INF, -INF)
	
	for mesh in meshes:
		if mesh.mesh:
			var aabb = mesh.mesh.get_aabb()
			# Get the mesh's world position relative to the object
			var mesh_min = mesh.position + aabb.position
			var mesh_max = mesh.position + aabb.position + aabb.size
			
			bounds_min.x = min(bounds_min.x, mesh_min.x)
			bounds_min.y = min(bounds_min.y, mesh_min.y)
			bounds_min.z = min(bounds_min.z, mesh_min.z)
			
			bounds_max.x = max(bounds_max.x, mesh_max.x)
			bounds_max.y = max(bounds_max.y, mesh_max.y)
			bounds_max.z = max(bounds_max.z, mesh_max.z)
	
	# Calculate the visual center and size
	var visual_center = (bounds_min + bounds_max) / 2.0
	var size = bounds_max - bounds_min
	var max_dim = max(size.x, max(size.y, size.z))
	
	print("   📦 Object bounds: ", bounds_min, " to ", bounds_max)
	print("   🎯 Calculated visual center: ", visual_center)
	print("   📏 Object size: ", size)
	
	# Scale the object to fit nicely in view
	var target_size = 3.0
	var scale_factor = target_size / max_dim
	wrapper.scale = Vector3(scale_factor, scale_factor, scale_factor)
	
	# FIRST: Position the object so its visual center is at the wrapper's origin
	object_copy.position = -visual_center
	
	# THEN apply manual offset to fine-tune
	object_copy.position += Vector3(manual_offset_x, manual_offset_y, manual_offset_z)
	
	# Position the wrapper at the view center
	wrapper.position = Vector3(0, 0, -2)
	
	print("   📏 Scale factor: ", scale_factor)
	print("   📍 Object position relative to wrapper: ", object_copy.position)
	print("   📍 Wrapper position: ", wrapper.position)
	
	# Make camera look at the wrapper
	cam.look_at(wrapper.position, Vector3.UP)
	
	# Wait for render
	await RenderingServer.frame_post_draw
	
	print("✅ Viewport setup complete")

func _input(event):
	if not visible or not current_object:
		return
	
	# Check if mouse is over the viewport
	var mouse_pos = get_global_mouse_position()
	var viewport_rect = Rect2(viewport_container.global_position, viewport_container.size)
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and viewport_rect.has_point(mouse_pos):
				is_dragging = true
				last_mouse_position = mouse_pos
				print("🖱️ Drag started")
			else:
				is_dragging = false
				print("🖱️ Drag ended")
	
	elif event is InputEventMouseMotion and is_dragging:
		var delta = mouse_pos - last_mouse_position
		last_mouse_position = mouse_pos
		
		# Rotate the wrapper around its center
		var rotation_speed = 0.005
		current_object.rotation.y -= delta.x * rotation_speed
		current_object.rotation.x += delta.y * rotation_speed
		
		# Clamp vertical rotation to avoid flipping
		current_object.rotation.x = clamp(current_object.rotation.x, -1.0, 1.0)

func _on_take():
	print("Take button pressed")
	if on_take_callback.is_valid():
		on_take_callback.call()
	
	# Cleanup viewport
	for child in render_viewport.get_children():
		if child is Camera3D or child is Light3D:
			continue
		child.queue_free()
	current_object = null
	
	# Restore mouse mode
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hide()

func _on_cancel():
	print("Cancel button pressed")
	if on_cancel_callback.is_valid():
		on_cancel_callback.call()
	
	# Cleanup viewport
	for child in render_viewport.get_children():
		if child is Camera3D or child is Light3D:
			continue
		child.queue_free()
	current_object = null
	
	# Restore mouse mode
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hide()
