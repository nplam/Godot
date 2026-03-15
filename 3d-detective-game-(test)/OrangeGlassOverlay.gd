# OrangeGlassesOverlay.gd
extends ColorRect

var is_on: bool = false

func _ready():
	color = Color(1.0, 0.6, 0.0, 0.15)
	mouse_filter = MOUSE_FILTER_IGNORE
	visible = false
	print("👓 Orange Glasses overlay ready")

func toggle():
	is_on = !is_on
	visible = is_on
	print("👓 Orange Glasses: ", "ON" if is_on else "OFF")
