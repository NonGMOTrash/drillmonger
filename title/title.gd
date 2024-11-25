extends VBoxContainer

@onready var play: Button = $play

func _ready() -> void:
	get_tree().paused = false
	play.grab_focus()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://main/main.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
