extends Entity
class_name Slime

const POOP: PackedScene = preload("res://projectile/poop/poop.tscn")
# note: startup is built into the length of "spawn" animation
const MOVE_INTERVAL: float = 1.1
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
		move_cooldown = 99.9 # temporary, get's actually reset during animation in attack()
		sprite_animation.play("attack")
	
	if velocity.length() > 340.0:
		hitbox_cshape.disabled = false
	else:
		hitbox_cshape.disabled = true
		if not sprite_animation.is_playing():
			sprite.frame = 0
	hurtbox_cshape.disabled = !hitbox_cshape.disabled
	
	spawn_cooldown -= delta
	if spawn_cooldown <= 0:
		var poop: Projectile = POOP.instantiate()
		poop.source = self
		poop.global_position = global_position
		main.room.add_child(poop)
		spawn_cooldown = SPAWN_INTERVAL
	
	super._physics_process(delta)

func attack() -> void:
	velocity = global_position.direction_to(player.global_position).normalized() * MOVE_STRENGTH
	move_cooldown = MOVE_INTERVAL
