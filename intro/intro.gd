extends Control

const TITLE: PackedScene = preload("res://title/title.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventJoypadButton:
		_on_animation_player_animation_finished("")

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	get_tree().change_scene_to_packed(TITLE)
