# Intro.gd - Inspector configurable
extends Control

enum IntroPart { PART1, PART2 }

# ============ EXPORT VARIABLES - Configure in Inspector ============
@export var typing_speed: float = 0.08
@export var text_font_size: int = 24
@export var text_color: Color = Color(0.9, 0.9, 0.9)
@export var line_spacing: int = 10
@export var top_spacer_height: int = 80
@export var bottom_spacer_height: int = 40
@export var button_width: int = 200
@export var button_height: int = 50

# Part 1: Story/Context - Can be edited in Inspector as multiline string
@export_multiline var part1_text: String = "Mr. Bobby, millionaire heir to Security Dynamics Inc., had a special room where he kept his most prized possessions, where only a few individuals were allowed in - the maid, Luela, to dust the room under specific supervision, the developer of the security system, Hector, and, of course, his wife, Mrs. Bobby. 
\nOne day, Mr. Bobby was showing his prized possessions off to his esteemed colleague, Ms. Albani (for the tenth time). This time, Ms. Albani started to laugh uncontrollably and told Mr. Bobby that, for him running a security company, the picture in the room is fake. Angry, Mr. Bobby got an art expert to look at the painting, which was indeed fake. Mr. Bobby called the police, and here you are, an emerging detective, to see what has happened. 
"

# Part 2: Four Suspects Introduction - Can be edited in Inspector
@export_multiline var part2_text: String = "Now, let's meet the suspects...\n\nMr. Bobby (the owner):
\nMr. Bobby claims that there is no way he would be exchanging his prized possessions. However, it has been known that his investments in the stock market have recently been trending downwards. Mr. Bobby has downplayed this fact and insists that he is a righteous man who would not stoop to selling his paintings.
\n\nMrs. Bobby (the wife): 
\nMrs. Bobby is used to a life of leisure as the wife of a wealthy man. With the change in fortune reducing much of Mr. Bobby’s income, Mrs. Bobby may have stooped to selling some of the artwork. More importantly, she has a key to the room that is not monitored as rigorously as others.
\n\nLuela (the maid): 
\nLuela is always under strict surveillance when she is let into the room to dust the artifacts. However, she has recently entered the city-wide championship of locksmiths. One of the events includes opening a lock within a minute and replicating keys using minimal tools. Being able to break into Bobby’s prized room would ensure bragging rights for the foreseeable future.
\n\nHector (the security guard): 
\nHector has recently been looking into opening his own security company. After years of hard work for Mr. Bobby, Hector now feels it is time to try his luck on his own without so much stress and micromanaging. Of course, when he leaves the company, he is planning on taking everything he knows about the security systems that HE developed.
"

# ============ INTERNAL VARIABLES ============
var current_part: IntroPart = IntroPart.PART1
var current_text: String = ""
var full_text: String = ""
var typing_timer: float = 0.0
var is_typing: bool = true

# Node references
var text_label: Label
var continue_button: Button
var skip_button: Button
var background: ColorRect
var scroll_container: ScrollContainer
var main_container: Control
var top_spacer: Control
var bottom_spacer: Control

func _ready():
	print("🎬 Intro _ready called")
	
	# Make intro full screen
	_set_full_rect()
	
	# Build UI dynamically using Inspector values
	_build_ui()
	
	# Start with Part 1
	_start_part(IntroPart.PART1)
	
	# Make sure intro is visible
	visible = true
	print("🎬 Intro ready")

func _set_full_rect():
	"""Make the intro fill the entire screen"""
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

func _build_ui():
	"""Build the entire UI using Inspector values"""
	
	# Create Background
	background = ColorRect.new()
	background.name = "Background"
	background.color = Color(0, 0, 0, 0.9)
	background.anchor_left = 0.0
	background.anchor_top = 0.0
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.offset_left = 0
	background.offset_top = 0
	background.offset_right = 0
	background.offset_bottom = 0
	background.gui_input.connect(_on_background_click)
	add_child(background)
	
	# Create Main VBoxContainer
	main_container = VBoxContainer.new()
	main_container.name = "MainContainer"
	main_container.anchor_left = 0.0
	main_container.anchor_top = 0.0
	main_container.anchor_right = 1.0
	main_container.anchor_bottom = 1.0
	main_container.offset_left = 50
	main_container.offset_top = 50
	main_container.offset_right = -50
	main_container.offset_bottom = -50
	main_container.add_theme_constant_override("separation", 20)
	add_child(main_container)
	
	# Create ScrollContainer
	scroll_container = ScrollContainer.new()
	scroll_container.name = "TextScrollContainer"
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
	main_container.add_child(scroll_container)
	
	# Create inner container for text with spacers
	var inner_vbox = VBoxContainer.new()
	inner_vbox.name = "InnerVBox"
	inner_vbox.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	scroll_container.add_child(inner_vbox)
	
	# Add top spacer
	top_spacer = Control.new()
	top_spacer.name = "TopSpacer"
	top_spacer.custom_minimum_size = Vector2(0, top_spacer_height)
	inner_vbox.add_child(top_spacer)
	
	# Create TextLabel
	text_label = Label.new()
	text_label.name = "TextLabel"
	text_label.add_theme_font_size_override("font_size", text_font_size)
	text_label.add_theme_color_override("font_color", text_color)
	text_label.add_theme_constant_override("line_spacing", line_spacing)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	inner_vbox.add_child(text_label)
	
	# Add bottom spacer
	bottom_spacer = Control.new()
	bottom_spacer.name = "BottomSpacer"
	bottom_spacer.custom_minimum_size = Vector2(0, bottom_spacer_height)
	inner_vbox.add_child(bottom_spacer)
	
	# Create ContinueButton
	continue_button = Button.new()
	continue_button.name = "ContinueButton"
	continue_button.text = "Continue"
	continue_button.size = Vector2(button_width, button_height)
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_button.pressed.connect(_on_continue_pressed)
	main_container.add_child(continue_button)
	
	# Create SkipButton
	skip_button = Button.new()
	skip_button.name = "SkipButton"
	skip_button.text = "Skip"
	skip_button.size = Vector2(80, 40)
	skip_button.anchor_left = 1.0
	skip_button.anchor_right = 1.0
	skip_button.offset_left = -90
	skip_button.offset_top = 10
	skip_button.offset_right = -10
	skip_button.offset_bottom = 50
	skip_button.pressed.connect(_on_skip_pressed)
	add_child(skip_button)
	
	print("   ✅ UI built with Inspector values")
	print("      Top spacer height: ", top_spacer_height)
	print("      Text font size: ", text_font_size)
	print("      Button size: ", button_width, "x", button_height)

func _start_part(part: IntroPart):
	current_part = part
	
	match part:
		IntroPart.PART1:
			full_text = part1_text
		IntroPart.PART2:
			full_text = part2_text
	
	current_text = ""
	if text_label:
		text_label.text = ""
	is_typing = true
	typing_timer = 0.0
	
	# Scroll to top
	if scroll_container:
		scroll_container.scroll_vertical = 0
	
	if continue_button:
		continue_button.text = "Continue" if part == IntroPart.PART1 else "Start Game"

func _scroll_to_bottom():
	"""Scroll to the bottom of the scroll container"""
	if scroll_container:
		scroll_container.scroll_vertical = 10000

func _process(delta):
	if is_typing and text_label:
		typing_timer += delta
		if typing_timer >= typing_speed:
			typing_timer = 0.0
			if current_text.length() < full_text.length():
				current_text += full_text[current_text.length()]
				text_label.text = current_text
				
				# Auto-scroll to bottom as text types
				_scroll_to_bottom()
			else:
				is_typing = false

func _on_continue_pressed():
	SoundManager.play_click()
	
	if is_typing:
		current_text = full_text
		if text_label:
			text_label.text = full_text
		is_typing = false
	else:
		match current_part:
			IntroPart.PART1:
				_start_part(IntroPart.PART2)
			IntroPart.PART2:
				_finish_intro()

func _on_skip_pressed():
	SoundManager.play_click()
	_finish_intro()

func _on_background_click(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_finish_intro()

func show_intro():
	"""Show the intro and reset to Part 1"""
	print("🎬 Showing intro")
	_start_part(IntroPart.PART1)
	visible = true
	modulate = Color(1, 1, 1, 1)

func _finish_intro():
	# Fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)
	await tween.finished
	
	# Hide instead of freeing
	visible = false
	modulate = Color(1, 1, 1, 1)
