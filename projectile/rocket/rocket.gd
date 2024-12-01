extends Projectile
class_name Rocket

const PARTICLE_EXPLOSION: PackedScene = preload("res://effects/particle_explosion.tscn")

const TRACKING: float = 1.75

@onready var main: Main = get_tree().current_scene
@onready var player: Player = main.player

func _ready() -> void:
	direction = global_position.direction_to(player.global_position)
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	var to_player: float = global_position.angle_to_point(player.global_position)
	rotation = rotate_toward(rotation, to_player, TRACKING * delta)
	direction = Vector2.from_angle(rotation)
	
	super._physics_process(delta)

func _on_hitbox_tree_exited() -> void:
	var particle: Particle = PARTICLE_EXPLOSION.instantiate()
	particle.global_position = global_position
	main.room.call_deferred("add_child", particle)
