# MagnifierUI.gd - With centered view
extends TextureRect

var is_active: bool = false
var screen_center: Vector2

func _ready():
	MagnifierManager.register_magnifier_ui(self)
	screen_center = get_viewport().size / 2
	hide()

func set_active(active: bool):
	is_active = active
	visible = active
	
	if active:
		# Start at screen center
		var size = get_rect().size
		position = screen_center - size / 2

func update_position(mouse_pos: Vector2):
	if not is_active:
		return
	var size = get_rect().size
	# Center the magnifier on mouse
	position = mouse_pos - size / 2
