# FingerprintBrush.gd
extends RigidBody3D

@onready var brush_model: Node3D = $BrushModel  # Reference to the GLB model
@onready var detection_area: Area3D = $DetectionArea
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var is_active: bool = false
var detected_surfaces: Array = []

func _ready():
	# Disable physics when not active
	freeze = true  # RigidBody3D won't move when frozen
	# Start hidden
	hide()
	if detection_area:
		detection_area.monitoring = false
		detection_area.area_entered.connect(_on_area_entered)
		detection_area.area_exited.connect(_on_area_exited)
	
	print("🖌️ Fingerprint Brush ready")

func toggle_active():
	is_active = !is_active
	visible = is_active
	
	# Unfreeze when active so hand can move it
	freeze = !is_active
	
	if detection_area:
		detection_area.monitoring = is_active
		
	print("🖌️ Brush ", "equipped" if is_active else "stowed")

func _input(event):
	if not is_active:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if detected_surfaces.size() > 0:
			dust_nearest_surface()

func _on_area_entered(area: Area3D):
	if area.is_in_group("fingerprint_surface") and area.has_method("on_fingerprint_dusted"):
		if not area in detected_surfaces:
			detected_surfaces.append(area)
			print("👆 Fingerprint surface detected")

func _on_area_exited(area: Area3D):
	if area in detected_surfaces:
		detected_surfaces.erase(area)

func dust_nearest_surface():
	if detected_surfaces.size() == 0:
		return
	
	var closest = detected_surfaces[0]
	var closest_dist = global_position.distance_squared_to(closest.global_position)
	
	for surface in detected_surfaces:
		var dist = global_position.distance_squared_to(surface.global_position)
		if dist < closest_dist:
			closest = surface
			closest_dist = dist
	
	if closest.has_method("on_fingerprint_dusted"):
		print("🖌️ Dusting fingerprint...")
		closest.on_fingerprint_dusted()
		play_dust_animation()

func play_dust_animation():
	var tween = create_tween()
	tween.tween_property(brush_model, "position:y", brush_model.position.y + 0.02, 0.1)
	tween.tween_property(brush_model, "position:y", brush_model.position.y, 0.1)
