extends Entity
class_name Slime

# note: startup is built into the length of "spawn" animation
const MOVE_INTERVAL: float = 0.8
const MOVE_STRENGTH: float = 500.0
const SPAWN_INTERVAL: float = 2.4

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox_cshape: CollisionShape2D = $hitbox/CollisionShape2D
@onready var hurtbox_cshape: CollisionShape2D = $hurtbox/CollisionShape2D
@onready var sprite_animation: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var main: Main = get_tree().current_scene
@onready var player: Player = main.player

var move_cooldown: float = MOVE_INTERVAL
var spawn_cooldown: float = SPAWN_INTERVAL

func _init() -> void:
	health = 3
	slow_down = 20 * 60.0

func _physics_process(delta: float) -> void:
	if sprite_animation.is_playing() and sprite_animation.current_animation == "spawn":
		return
	
	move_cooldown -= delta
	if move_cooldown <= 0:
		velocity = global_position.direction_to(player.global_position).normalized() * MOVE_STRENGTH
		move_cooldown = MOVE_INTERVAL
	
	if velocity.length() > 300.0:
		hitbox_cshape.disabled = false
		sprite.frame = 1
	else:
		hitbox_cshape.disabled = true
		sprite.frame = 0
	hurtbox_cshape.disabled = !hitbox_cshape.disabled
	
	spawn_cooldown -= delta
	if spawn_cooldown <= 0:
		var new_slime: Slime = self.duplicate()
		new_slime.global_position = global_position
		main.room.add_child(new_slime)
		spawn_cooldown = SPAWN_INTERVAL
	
	super._physics_process(delta)
