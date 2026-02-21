extends CanvasLayer

@onready var label: Label = $BackgroundPanel/PromptLabel   # adjust path if needed
@onready var panel: Panel = $BackgroundPanel

func show_prompt(message: String):
	label.text = message
	panel.show()

func hide_prompt():
	panel.hide()
