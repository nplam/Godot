# BlueLight.gd
extends Node3D

@onready var visual_light: SpotLight3D = $SpotLight3D
@onready var detection_area: Area3D = $DetectionArea

var is_on: bool = false

func _ready():
	# Start with light off
	visual_light.visible = false
	detection_area.monitoring = false
	
	# Configure blue light properties
	visual_light.light_color = Color(0.27, 0.53, 1.0)  # Bright blue #4488FF
	visual_light.light_energy = 1.5
	visual_light.spot_range = 5.0
	visual_light.spot_angle = 45.0
	
	# Connect detection signal
	detection_area.area_entered.connect(_on_area_entered)
	
	print("🔵 Blue Light ready")

func set_active(active: bool):
	is_on = active
	visual_light.visible = active
	detection_area.monitoring = active

func _on_area_entered(area: Area3D):
	if not is_on:
		return
	
	# Check if orange glasses are on
	var glasses = get_node("/root/YourMainScene/UI/OrangeGlassesOverlay")
	if not glasses or not glasses.is_on:
		# Optional: Show hint
		return
	
	if area.is_in_group("fingerprint_surface") and area.has_method("on_blue_light_detected"):
		print("🔵 Blue light detected fingerprint on: ", area.name)
		area.on_blue_light_detected()
