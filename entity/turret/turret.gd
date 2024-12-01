extends Entity
class_name Turret

const ROCKET: PackedScene = preload("res://projectile/rocket/rocket.tscn")

const SHOT_INTERVAL: float = 2.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var warning: CPUParticles2D = $warning

@onready var main: Main = get_tree().current_scene
@onready var player: Player = main.player

var shot_cooldown: float = SHOT_INTERVAL
var has_warned: bool = false

func _init() -> void:
	top_speed = 0
	slow_down = 1200
	
	health = 2

func _physics_process(delta: float) -> void:
	sprite.flip_h = (player.global_position.x < global_position.x)
	if player.global_position.y > global_position.y:
		sprite.frame = 1
	else:
		sprite.frame = 0
	
	shot_cooldown -= delta
	if shot_cooldown < 0.2 and not has_warned:
		warning.direction = global_position.direction_to(player.global_position)
		warning.emitting = true
		has_warned = true
	if shot_cooldown <= 0:
		var rocket: Rocket = ROCKET.instantiate()
		rocket.source = self
		rocket.global_position = global_position
		main.room.add_child(rocket)
		
		shot_cooldown = SHOT_INTERVAL
		has_warned = false
