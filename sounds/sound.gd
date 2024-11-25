extends AudioStreamPlayer
class_name Sound

@export var pitch_shift: float = 0

func _ready() -> void:
	pitch_scale += randf_range(-pitch_shift, pitch_shift)

func _on_finished() -> void:
	queue_free()
