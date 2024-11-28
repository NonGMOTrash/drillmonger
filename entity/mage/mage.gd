extends Entity
class_name Mage

const STARTUP_TIME: float = 0.8
const SHOT_INTERVAL: float = 7.0
const TP_INTERVAL: float = 2.0

@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var room: Node = get_parent()

var player: Player

var projectile: PackedScene = preload("res://projectile/dart/dart.tscn")
var startup_time: float = STARTUP_TIME
var cast_time: float = 0.0
var tp_time: float = 1.0

func _init() -> void:
	health = 5

func _ready() -> void:
	player = get_tree().current_scene.player

func _physics_process(delta: float) -> void:
	if startup_time > 0:
		startup_time -= delta
		return
	
	if player.global_position.x > global_position.x:
		sprite.flip_h = false
	else:
		sprite.flip_h = true
	
	if cast_time <= 0:
		animation.queue("cast")
		cast_time = SHOT_INTERVAL
	else:
		cast_time -= delta
	
	if tp_time <= 0:
		animation.queue("teleport")
		tp_time = TP_INTERVAL
	else:
		tp_time -= delta
	
	super._physics_process(delta)

func cast() -> void:
	for i in range(0, 8):
		var dart: Projectile = projectile.instantiate()
		dart.global_position = global_position
		dart.direction = Vector2.from_angle(i * 0.7854)
		dart.source = self
		room.add_child(dart)

func teleport() -> void:
	global_position = Vector2(randf_range(40, 600), randf_range(40, 320))
