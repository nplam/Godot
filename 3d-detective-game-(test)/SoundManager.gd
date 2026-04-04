# SoundManager.gd - All MP3 sounds with shared key press sound
extends Node

# Singleton reference (don't use SoundManager as type here)
static var instance

# Audio players
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var footstep_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer

# Sound paths - all MP3
# Sound paths - CORRECT PATH: Assets/Sounds/ (capital A, capital S)
var ambient_music: AudioStream = preload("res://Assets/Sounds/ambient_music.mp3")
var footstep: AudioStream = preload("res://Assets/Sounds/footstep.mp3")
var click: AudioStream = preload("res://Assets/Sounds/click.mp3")
var evidence_collect: AudioStream = preload("res://Assets/Sounds/evidence_collect.mp3")
var evidence_correct: AudioStream = preload("res://Assets/Sounds/evidence_correct.mp3")
var evidence_wrong: AudioStream = preload("res://Assets/Sounds/evidence_wrong.mp3")
var case_solved: AudioStream = preload("res://Assets/Sounds/case_solved.mp3")
var key_press: AudioStream = preload("res://Assets/Sounds/key_press.mp3")

# Volume settings (in dB - negative values are quieter)
var master_volume: float = 0.0
var music_volume: float = -8.0
var sfx_volume: float = -3.0
var ui_volume: float = -5.0

func _ready():
	# Set up singleton
	instance = self
	
	# Create audio players
	music_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	footstep_player = AudioStreamPlayer.new()
	ui_player = AudioStreamPlayer.new()
	
	add_child(music_player)
	add_child(sfx_player)
	add_child(footstep_player)
	add_child(ui_player)
	
	# Set volumes
	_update_volumes()
	
	# Start ambient music
	start_ambient_music()
	
	print("🎵 SoundManager ready - Ambient music playing")

func _update_volumes():
	music_player.volume_db = master_volume + music_volume
	sfx_player.volume_db = master_volume + sfx_volume
	footstep_player.volume_db = master_volume + sfx_volume
	ui_player.volume_db = master_volume + ui_volume

# ============ MUSIC FUNCTIONS ============
func start_ambient_music():
	if ambient_music:
		music_player.stream = ambient_music
		music_player.play()
		music_player.finished.connect(_on_music_finished)
		print("🎵 Ambient music started")

func stop_music():
	music_player.stop()

func _on_music_finished():
	# Loop the music
	music_player.play()

# ============ SOUND EFFECT FUNCTIONS ============
func play_footstep():
	if footstep:
		footstep_player.stream = footstep
		footstep_player.play()

func play_click():
	if click:
		ui_player.stream = click
		ui_player.play()

func play_evidence_collect():
	if evidence_collect:
		sfx_player.stream = evidence_collect
		sfx_player.play()

func play_evidence_correct():
	if evidence_correct:
		sfx_player.stream = evidence_correct
		sfx_player.play()

func play_evidence_wrong():
	if evidence_wrong:
		sfx_player.stream = evidence_wrong
		sfx_player.play()

func play_case_solved():
	if case_solved:
		sfx_player.stream = case_solved
		sfx_player.play()

# ============ ALL THESE USE THE SAME KEY_PRESS SOUND ============
func play_uv_on():
	if key_press:
		sfx_player.stream = key_press
		sfx_player.play()

func play_uv_off():
	if key_press:
		sfx_player.stream = key_press
		sfx_player.play()

func play_blue_on():
	if key_press:
		sfx_player.stream = key_press
		sfx_player.play()

func play_blue_off():
	if key_press:
		sfx_player.stream = key_press
		sfx_player.play()

func play_glasses_on():
	if key_press:
		sfx_player.stream = key_press
		sfx_player.play()

func play_case_board_open():
	if key_press:
		sfx_player.stream = key_press
		sfx_player.play()

func play_case_board_close():
	if key_press:
		sfx_player.stream = key_press
		sfx_player.play()

# ============ VOLUME CONTROL ============
func set_master_volume(value: float):
	master_volume = value
	_update_volumes()

func set_music_volume(value: float):
	music_volume = value
	_update_volumes()

func set_sfx_volume(value: float):
	sfx_volume = value
	_update_volumes()

func set_ui_volume(value: float):
	ui_volume = value
	_update_volumes()
