extends Entity
class_name Cannon

const STARTUP_TIME: float = 1.2
const SHOT_INTERVAL: float = 2.0
const SHOT_RECOIL: float = 600.0

@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var room: Node = get_parent()
@onready var sound: AudioStreamPlayer2D = $sound

@onready var player: Player = get_tree().current_scene.player

var projectile: PackedScene = preload("res://projectile/ball/ball.tscn")
var startup_time: float = STARTUP_TIME
var shot_time: float = 0.0

func _physics_process(delta: float) -> void:
	if startup_time > 0:
		startup_time -= delta
		return
	
	if player.global_position.x > global_position.x:
		sprite.flip_h = false
	else:
		sprite.flip_h = true
	
	if not animation.is_playing():
		if player.global_position.y < global_position.y:
			sprite.frame = 2
		else:
			sprite.frame = 0
	
	if shot_time <= 0:
		if sprite.frame == 0:
			animation.play("shoot_down")
		else:
			animation.play("shoot_up")
		shot_time = SHOT_INTERVAL
	else:
		shot_time -= delta
	
	super._physics_process(delta)

func shoot() -> void:
	var shot: Projectile = projectile.instantiate()
	shot.global_position = global_position
	shot.direction = global_position.direction_to(player.global_position)
	shot.source = self
	room.add_child(shot)
	
	sound.play()
	
	velocity -= global_position.direction_to(player.global_position) * SHOT_RECOIL
