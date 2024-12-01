extends Entity
class_name Totem

const MAGE: PackedScene = preload("res://entity/mage/mage.tscn")

const LIGHTING_INTERVAL: float = 0.05
const SUMMON_INTERVAL: float = 3.5

@onready var lightning: Sprite2D = $lightning
@onready var lightning_sound: AudioStreamPlayer = $lightning/AudioStreamPlayer
@onready var hitbox: Area2D = $hitbox
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var circle: AnimatedSprite2D = $circle
@onready var summon_sound: AudioStreamPlayer2D = $circle/AudioStreamPlayer2D

@onready var main: Main = get_tree().current_scene
@onready var player: Player = main.player

var startup_time: float = 0.5
var lightning_cooldown: float = LIGHTING_INTERVAL
var summon_cooldown: float = SUMMON_INTERVAL

func _init() -> void:
	top_speed = 0.0
	slow_down = 9999.9
	
	health = 20

func _ready() -> void:
	startup_time += global_position.distance_to(player.global_position) / 300.0

func _physics_process(delta: float) -> void:
	if startup_time > 0:
		startup_time -= delta
		return
	
	if player == null:
		player = get_tree().current_scene.player
	
	lightning_cooldown -= delta
	if lightning_cooldown <= 0:
		lightning.global_position = player.global_position + (player.velocity.normalized() * 100.0)
		if lightning.global_position.x > MAP_BORDER.x:
			lightning.global_position.x = 0
		if lightning.global_position.x < 0:
			lightning.global_position.x = MAP_BORDER.x
		if lightning.global_position.y > MAP_BORDER.y:
			lightning.global_position.y = 0
		if lightning.global_position.y < 0:
			lightning.global_position.y = MAP_BORDER.y
		hitbox.global_position = lightning.global_position
		
		animation.play("strike")
		lightning_cooldown = LIGHTING_INTERVAL + animation.current_animation_length
	
	summon_cooldown -= delta
	if summon_cooldown < 0.8 and not circle.visible:
		circle.visible = true
		circle.global_position = Vector2(randf_range(0,640), randf_range(0,360))
		summon_sound.playing = true
	if summon_cooldown <= 0:
		circle.visible = false
		var new_mage: Mage = MAGE.instantiate()
		new_mage.global_position = circle.global_position
		main.enemies_left += 1
		new_mage.connect("death", main.on_enemy_death)
		main.room.add_child(new_mage)
		summon_cooldown = SUMMON_INTERVAL
