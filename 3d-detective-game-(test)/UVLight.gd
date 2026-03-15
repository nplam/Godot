# UVLight.gd - Handles UV light toggling and evidence detection (blood + shoeprints)
extends Node3D

# References to our child nodes
@onready var visual_light: SpotLight3D = $UVLight
@onready var detection_area: Area3D = $DetectionArea

# Track whether the light is on
var is_on: bool = false
var detected_evidence: Array = []  # Keep track of all evidence currently in the light

func _ready():
	# Start with light off
	visual_light.visible = false
	detection_area.monitoring = false
	
	# Connect detection signals
	detection_area.area_entered.connect(_on_area_entered)
	detection_area.area_exited.connect(_on_area_exited)
	
	print("🔦 UV Light system ready on Hand node")

func _input(event):
	if event.is_action_pressed("toggle_uv"):
		toggle_light()

func toggle_light():
	is_on = !is_on
	visual_light.visible = is_on
	detection_area.monitoring = is_on
	
	if is_on:
		print("🔦 Light turned ON")
	else:
		print("UV Light OFF")
		reset_all_evidence()  # Hide all evidence when light turns off

func _on_area_entered(area: Area3D):
	# Check for blood stains
	if area.is_in_group("blood_stain") and area.has_method("on_uv_detected"):
		if not area in detected_evidence:
			detected_evidence.append(area)
			area.on_uv_detected()
			print("🩸 Blood stain detected. Total: ", detected_evidence.size())
	
	# Check for shoeprints
	elif area.is_in_group("shoeprint") and area.has_method("on_uv_detected"):
		if not area in detected_evidence:
			detected_evidence.append(area)
			area.on_uv_detected()
			print("👣 Shoeprint detected. Total: ", detected_evidence.size())

func _on_area_exited(area: Area3D):
	if area in detected_evidence:
		detected_evidence.erase(area)
		if area.has_method("reset_glow"):
			area.reset_glow()
		print("🔦 Evidence exited. Remaining: ", detected_evidence.size())

# Helper to hide all evidence when light turns off
func reset_all_evidence():
	for evidence in detected_evidence:
		if is_instance_valid(evidence) and evidence.has_method("reset_glow"):
			evidence.reset_glow()
	detected_evidence.clear()

# Called by Player.gd when selecting tools
func set_active(active: bool):
	is_on = active
	visual_light.visible = active
	detection_area.monitoring = active
