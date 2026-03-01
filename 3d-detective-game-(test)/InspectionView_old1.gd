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
	cam.position = Vector3(0, 0, 5)  # Camera further back
	render_viewport.add_child(cam)
	
	# 👇 ADD THIS LINE HERE - Set viewport size to match display
	render_viewport.size = viewport_display.size  # Use dynamic size	
	
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
	
	# ----- DEBUG VISUALS -----
	# Add a visible grid
	var grid = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(10, 10)
	plane_mesh.subdivide_width = 20
	plane_mesh.subdivide_depth = 20
	grid.mesh = plane_mesh
	grid.position = Vector3(0, -1, -2)
	var grid_mat = StandardMaterial3D.new()
	grid_mat.albedo_color = Color(0.3, 0.3, 0.3, 0.5)
	grid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	grid.material_override = grid_mat
	render_viewport.add_child(grid)
	
	# Add colored axis lines
	var axis_size = 5.0
	
	# X axis (red)
	var x_line = MeshInstance3D.new()
	var x_mesh = ImmediateMesh.new()
	x_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	x_mesh.surface_set_color(Color.RED)
	x_mesh.surface_add_vertex(Vector3(-axis_size, 0, -2))
	x_mesh.surface_add_vertex(Vector3(axis_size, 0, -2))
	x_mesh.surface_end()
	x_line.mesh = x_mesh
	render_viewport.add_child(x_line)
	
	# Y axis (green)
	var y_line = MeshInstance3D.new()
	var y_mesh = ImmediateMesh.new()
	y_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	y_mesh.surface_set_color(Color.GREEN)
	y_mesh.surface_add_vertex(Vector3(0, -axis_size, -2))
	y_mesh.surface_add_vertex(Vector3(0, axis_size, -2))
	y_mesh.surface_end()
	y_line.mesh = y_mesh
	render_viewport.add_child(y_line)
	
	# Z axis (blue)
	var z_line = MeshInstance3D.new()
	var z_mesh = ImmediateMesh.new()
	z_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	z_mesh.surface_set_color(Color.BLUE)
	z_mesh.surface_add_vertex(Vector3(0, 0, -2 - axis_size))
	z_mesh.surface_add_vertex(Vector3(0, 0, -2 + axis_size))
	z_mesh.surface_end()
	z_line.mesh = z_mesh
	render_viewport.add_child(z_line)
	
	# Add a sphere at the target center
	var center_sphere = MeshInstance3D.new()
	center_sphere.mesh = SphereMesh.new()
	center_sphere.position = Vector3(0, 0, -2)
	center_sphere.scale = Vector3(0.2, 0.2, 0.2)
	var sphere_mat = StandardMaterial3D.new()
	sphere_mat.albedo_color = Color.YELLOW
	sphere_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	center_sphere.material_override = sphere_mat
	render_viewport.add_child(center_sphere)
	# ----- END DEBUG VISUALS -----
	
	# Create a wrapper node to hold the object (this helps with centering)
	var wrapper = Node3D.new()
	wrapper.name = "ObjectWrapper"
	render_viewport.add_child(wrapper)
	
	# Create a copy of the original object
	var object_copy = interactable.duplicate()
	wrapper.add_child(object_copy)
	
	# Reset all materials
	var all_meshes = object_copy.find_children("*", "MeshInstance3D", true, false)
	print("   Found ", all_meshes.size(), " mesh(es) in copied object")
	
	for mesh in all_meshes:
		mesh.material_override = null
		print("   ✅ Reset material for: ", mesh.name)
	
	# Calculate the bounding box of the object
	var min_bounds = Vector3(INF, INF, INF)
	var max_bounds = Vector3(-INF, -INF, -INF)
	
	for mesh in all_meshes:
		if mesh.mesh:
			var aabb = mesh.mesh.get_aabb()
			var mesh_min = mesh.position + aabb.position
			var mesh_max = mesh.position + aabb.position + aabb.size
			
			min_bounds.x = min(min_bounds.x, mesh_min.x)
			min_bounds.y = min(min_bounds.y, mesh_min.y)
			min_bounds.z = min(min_bounds.z, mesh_min.z)
			
			max_bounds.x = max(max_bounds.x, mesh_max.x)
			max_bounds.y = max(max_bounds.y, mesh_max.y)
			max_bounds.z = max(max_bounds.z, mesh_max.z)
	
	# Calculate object dimensions
	var size = max_bounds - min_bounds
	var max_dimension = max(size.x, size.y, size.z)
	
	print("   📦 Object bounds: ", min_bounds, " to ", max_bounds)
	print("   📏 Object size: ", size)
	print("   📏 Max dimension: ", max_dimension)
	
	# Scale the object to a reasonable size
	var target_size = 4.0  # Increased from 3.0
	var scale_factor = target_size / max_dimension
	
	# Apply scale to the object (not the wrapper)
	object_copy.scale = Vector3(scale_factor, scale_factor, scale_factor)
	
	# Calculate the center of the object in local space
	var local_center = (min_bounds + max_bounds) / 2.0
	
	# Position the object so its center is at the wrapper's origin
	object_copy.position = -local_center
	
	# Now position the wrapper at the target location
	wrapper.position = Vector3(0, 0, -2)
	
	# Store the wrapper for rotation (so the whole object rotates around its center)
	current_object_copy = wrapper
	
	print("   📏 Scale factor: ", scale_factor)
	print("   📍 Local center: ", local_center)
	print("   📍 Object local position: ", object_copy.position)
	print("   📍 Wrapper position: ", wrapper.position)
	
	# Make the camera look at the wrapper
	cam.look_at(wrapper.position, Vector3.UP)
	
	# Wait for first render
	await RenderingServer.frame_post_draw
	
	# Assign texture to display
	viewport_display.texture = render_viewport.get_texture()
	viewport_display.modulate = Color.WHITE
	
	print("✅ Viewport setup complete for: ", interactable.object_name)

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
