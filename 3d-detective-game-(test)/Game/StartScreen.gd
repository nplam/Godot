# StartScreen.gd - Positions set in Inspector
extends Control

@onready var start_button = $StartButton
@onready var quit_button = $QuitButton
@onready var title_label = $Title
@onready var background = $Background

func _ready():
	# Make full screen
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# Style background
	background.color = Color(0.05, 0.05, 0.1)
	
	# Style title (only font and color, not position)
	title_label.add_theme_font_size_override("font_size", 56)
	#title_label.add_theme_color_override("font_color", Color(0.902, 0.0, 0.0, 1.0))
	title_label.add_theme_constant_override("shadow_size", 4)
	title_label.add_theme_color_override("shadow_color", Color(0, 0, 0))
	
	# Style buttons (only font and colors, not position)
	_style_button(start_button)
	_style_button(quit_button)
	
	# Connect buttons
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Start ambient music
	SoundManager.start_ambient_music()
	
	# Animate title
	_animate_title()

func _style_button(button: Button):
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.8, 0.6, 0.3)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	button.add_theme_stylebox_override("normal", style)
	
	# Hover effect
	var hover_style = style.duplicate()
	hover_style.bg_color = Color(0.35, 0.35, 0.45)
	hover_style.border_color = Color(1, 0.8, 0.4)
	button.add_theme_stylebox_override("hover", hover_style)

func _animate_title():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(title_label, "scale", Vector2(1.03, 1.03), 1.5)
	tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 1.5)

func _on_start_pressed():
	SoundManager.play_click()
	
	# Fade out effect
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	await tween.finished
	
	# Show intro
	var intro = get_node("/root/World/CanvasLayer/Intro")
	if intro:
		intro.show_intro()
	
	# Hide start screen
	queue_free()

func _on_quit_pressed():
	SoundManager.play_click()
	get_tree().quit()
