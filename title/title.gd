extends Control

@onready var main: VBoxContainer = $main
@onready var options: VBoxContainer = $options
# main
@onready var play: Button = $main/play
@onready var quit: Button = $main/quit
# options
@onready var fullscreen: CheckButton = $options/enable_fullscreen
@onready var volume_slider: HSlider = $options/volume/slider

func _ready() -> void:
	get_tree().paused = false
	play.grab_focus()
	
	if OS.has_feature("wasm"):
		quit.visible = false
	
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://main/main.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_options_pressed() -> void:
	main.visible = false
	options.visible = true
	
	fullscreen.grab_focus()

func _on_back_pressed() -> void:
	options.visible = false
	main.visible = true
	play.grab_focus()

func _on_enable_fullscreen_pressed() -> void:
	if fullscreen.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_MAXIMIZED)

func _on_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value))
