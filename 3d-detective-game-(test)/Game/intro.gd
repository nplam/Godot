# Intro.gd - With simple scrolling
extends Control

enum IntroPart { PART1, PART2 }

var current_part: IntroPart = IntroPart.PART1
var typing_speed: float = 0.03
var current_text: String = ""
var full_text: String = ""
var typing_timer: float = 0.0
var is_typing: bool = true

# Node references - will be found dynamically
var text_label: Label
var continue_button: Button
var skip_button: Button
var background: ColorRect
var scroll_container: ScrollContainer
var main_container: Control

# Part 1: Story/Context
var part1_text = "It was a dark and stormy night at the grand mansion...\n\n" + \
				 "A priceless artifact has been stolen from the museum collection.\n\n" + \
				 "Four people were present at the scene when the crime occurred.\n\n" + \
				 "As the lead detective, you must examine the evidence and identify the culprit.\n\n" + \
				 "Use your forensic tools to find hidden evidence:\n" + \
				 "• UV Light reveals shoeprints\n" + \
				 "• Blue Light with Orange Glasses reveals fingerprints\n" + \
                 "• Hair strands are visible to the naked eye"

# Part 2: Four Suspects Introduction
var part2_text = "Now, let's meet the suspects...\n\n" + \
				 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n" + \
				 "🔍 MR. BOBBY - The Owner\n" + \
				 "   • Brown hair\n" + \
				 "   • Wears loafers\n" + \
				 "   • Fingerprint ID: FP-001\n\n" + \
				 "🔍 MRS. BOBBY - The Wife\n" + \
				 "   • Red hair\n" + \
				 "   • Wears high heels\n" + \
				 "   • Fingerprint ID: FP-002\n\n" + \
				 "🔍 LULEA - The Maid\n" + \
				 "   • Blond hair\n" + \
				 "   • Wears flats\n" + \
				 "   • Fingerprint ID: FP-003\n\n" + \
				 "🔍 HECTOR - The Security Guard\n" + \
				 "   • Brown hair\n" + \
				 "   • Wears loafers\n" + \
				 "   • Fingerprint ID: FP-004\n\n" + \
				 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n" + \
				 "Collect 2 matching evidence on the same suspect to identify the culprit!\n\n" + \
                 "Good luck, Detective!"

func _ready():
	print("🎬 Intro _ready called")
	
	# Make intro full screen
	_set_full_rect()
	
	# Find nodes by name (flexible)
	_find_nodes()
	
	# Set up layout to prevent text overflow
	_setup_layout()
	
	# Style the text label if found
	if text_label:
		text_label.add_theme_font_size_override("font_size", 24)
		text_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		text_label.add_theme_constant_override("line_spacing", 10)
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		print("   ✅ TextLabel styled")
	else:
		print("   ⚠️ TextLabel not found - creating one")
		_create_text_label()
	
	# Connect buttons if found
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
		print("   ✅ Continue button connected")
	else:
		print("   ⚠️ ContinueButton not found")
		_create_continue_button()
	
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)
		print("   ✅ Skip button connected")
	else:
		print("   ⚠️ SkipButton not found")
		_create_skip_button()
	
	# Find background
	if background:
		background.gui_input.connect(_on_background_click)
	
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

func _find_nodes():
	"""Find nodes by common names"""
	# Try to find MainContainer (VBoxContainer)
	main_container = find_child("MainContainer", true, false)
	if not main_container:
		main_container = find_child("VBoxContainer", true, false)
	
	# Try to find ScrollContainer
	scroll_container = find_child("TextScrollContainer", true, false)
	if not scroll_container:
		scroll_container = find_child("ScrollContainer", true, false)
	
	# Try to find TextLabel
	text_label = find_child("TextLabel", true, false)
	if not text_label:
		text_label = find_child("Label", true, false)
	
	# Try to find ContinueButton
	continue_button = find_child("ContinueButton", true, false)
	if not continue_button:
		continue_button = find_child("Continue", true, false)
	
	# Try to find SkipButton
	skip_button = find_child("SkipButton", true, false)
	if not skip_button:
		skip_button = find_child("Skip", true, false)
	
	# Try to find Background
	background = find_child("Background", true, false)

func _setup_layout():
	"""Set up layout to prevent text overflow and ensure scrolling"""
	
	# Set up MainContainer (VBoxContainer)
	if main_container:
		main_container.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
		main_container.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
		main_container.add_theme_constant_override("separation", 20)
		print("   ✅ MainContainer configured")
	
	# Set up ScrollContainer
	if scroll_container:
		scroll_container.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
		scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		print("   ✅ ScrollContainer configured")
	
	# Set up TextLabel
	if text_label:
		text_label.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
		text_label.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		print("   ✅ TextLabel configured")
	
	# Set up ContinueButton
	if continue_button:
		continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		continue_button.size = Vector2(200, 50)
		print("   ✅ ContinueButton configured")

func _create_text_label():
	"""Create a text label if none exists"""
	text_label = Label.new()
	text_label.name = "TextLabel"
	text_label.add_theme_font_size_override("font_size", 24)
	text_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	text_label.add_theme_constant_override("line_spacing", 10)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	text_label.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
	
	# Add to ScrollContainer or direct
	if scroll_container:
		scroll_container.add_child(text_label)
	else:
		add_child(text_label)
	print("   ✅ Created TextLabel")

func _create_continue_button():
	"""Create a continue button if none exists"""
	continue_button = Button.new()
	continue_button.name = "ContinueButton"
	continue_button.text = "Continue"
	continue_button.size = Vector2(200, 50)
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Add to MainContainer or direct
	if main_container:
		main_container.add_child(continue_button)
	else:
		add_child(continue_button)
	continue_button.pressed.connect(_on_continue_pressed)
	print("   ✅ Created ContinueButton")

func _create_skip_button():
	"""Create a skip button if none exists"""
	skip_button = Button.new()
	skip_button.name = "SkipButton"
	skip_button.text = "Skip"
	skip_button.size = Vector2(100, 40)
	skip_button.position = Vector2(get_viewport().size.x - 110, 20)
	skip_button.pressed.connect(_on_skip_pressed)
	add_child(skip_button)
	print("   ✅ Created SkipButton")

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
	
	# Scroll to top when new text starts
	if scroll_container:
		scroll_container.scroll_vertical = 0
	
	if continue_button:
		continue_button.text = "Continue" if part == IntroPart.PART1 else "Start Game"

func _scroll_to_bottom():
	"""Scroll to the bottom of the scroll container"""
	if scroll_container:
		# Use a large number to scroll to bottom (works even if max is not ready)
		scroll_container.scroll_vertical = 10000
		# Then schedule a second scroll after the text updates
		await get_tree().create_timer(0.05).timeout
		if is_instance_valid(scroll_container):
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
