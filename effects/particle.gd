extends CPUParticles2D
class_name Particle

func _init() -> void:
	process_mode = PROCESS_MODE_ALWAYS

func _ready() -> void:
	emitting = true

func _on_finished() -> void:
	queue_free()
