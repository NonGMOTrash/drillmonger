extends Entity
class_name Player

const PARTICLE_PARRY: PackedScene = preload("res://effects/particle_parry.tscn")
const SFX_PARRY: PackedScene = preload("res://sounds/parry.tscn")

const DASH_COOLDOWN: float = 0.01
const DASH_STRENGTH: float = 1000.0
const PARRY_WINDOW: float = 0.016
const PARRY_LOCKOUT: float = 0.1
const DAMAGE: int = 1
const HIT_KNOCKBACK: float = 700.0

@onready var hitbox: Area2D = $hitbox
@onready var hitbox_cshape: CollisionShape2D = $hitbox/CollisionShape2D
@onready var hurtbox: Area2D = $hurtbox
@onready var parrybox: Area2D = $parrybox
@onready var sprite: Sprite2D = $Sprite2D
@onready var sprite_animation: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var animation: AnimationPlayer = $AnimationPlayer

@onready var main: Main = get_parent()

var cooldown_dash: float = 0
var stored_direction: Vector2 = Vector2.ZERO
var parrying_time: float = 0
var parrying_lockout: float = 0
var parry_success: bool = false

func _init() -> void:
	accel = 250 * 60
	top_speed = 170
	slow_down = 3000
	
	health = 3
	damage = 2

func _physics_process(delta: float) -> void:
	direction = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
	if direction != Vector2.ZERO:
		stored_direction = direction
	
	if cooldown_dash <= 0:
		if Input.is_action_just_pressed("dash"):
			velocity = stored_direction.normalized() * DASH_STRENGTH
			cooldown_dash = DASH_COOLDOWN
	else:
		cooldown_dash -= delta
	
	hitbox_cshape.disabled = (velocity.length() < 400.0)
	#hitbox.monitoring = (velocity.length() > 400.0)
	#hitbox.monitorable = hitbox.monitoring
	
	if parrying_time > 0:
		sprite.modulate = Color.YELLOW
	else:
		sprite.modulate = Color.WHITE
	
	
	if parrying_lockout > 0:
		parrying_lockout -= delta
	else:
		if Input.is_action_just_pressed("dash"):
			if parrying_time <= 0 or parry_success:
				parrybox.position = velocity.normalized() * 30 + Vector2(0, 6)
				parrying_time = PARRY_WINDOW
				hurtbox.monitoring = false
				parrybox.monitoring = true
				parry_success = false
		elif parrying_time > 0:
			parrying_time -= delta
			if parrying_time <= 0:
				hurtbox.monitoring = true
				parrybox.monitoring = false
				parrying_lockout = PARRY_LOCKOUT
	
	main.hud_health.text = str(health)
	
	if velocity.length() > 400:
		sprite_animation.play("drill")
		sprite.rotation = velocity.angle()
		sprite.rotation_degrees -= 90
	else:
		sprite.rotation = 0
		if direction != Vector2.ZERO:
			if abs(direction.x) > abs(direction.y):
				sprite_animation.play("walk_side")
			elif direction.y < 0:
				sprite_animation.play("walk_up")
			else:
				sprite_animation.play("walk_down")
		else:
			if sprite_animation.current_animation == "drill":
				sprite_animation.stop()
				sprite.frame = 0
			else:
				sprite_animation.stop()
	if direction.x > 0:
		sprite.flip_h = false
	elif direction.x < 0:
		sprite.flip_h = true
	
	super._physics_process(delta)

func _on_parrybox_area_entered(area: Area2D) -> void:
	if parrying_time <= 0 or not area.get_parent() is Projectile:
		return
	else:
		var projectile: Projectile = area.get_parent()
		projectile.queue_free()
		animation.play("parry")
		parrying_time = 0
		parrying_lockout = 0
		cooldown_dash = 0
		parry_success = true
		
		var particle: Particle = PARTICLE_PARRY.instantiate()
		particle.global_position = global_position
		get_tree().current_scene.add_child(particle)
		main.room_time -= 0.5
		
		var sound: Sound = SFX_PARRY.instantiate()
		get_tree().current_scene.add_child(sound)
		
		main.hitstop(2)
		
		for overlapping_hitbox in parrybox.get_overlapping_areas():
			if overlapping_hitbox.get_parent() is Projectile:
				overlapping_hitbox.get_parent().queue_free()
		
		hurtbox.monitoring = true

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.get_parent() is Entity and area.get_parent() != self:
		velocity = -global_position.direction_to(area.get_parent().global_position).normalized() * HIT_KNOCKBACK
		main.hitstop(3)

func _on_hitstop_timeout() -> void:
	if health > 0:
		get_tree().paused = false

func _on_hurtbox_was_hit(_from_pos: Vector2) -> void:
	sprite_animation.stop()
	sprite.frame = 14
	sprite.rotation = 0
	#await sprite_animation.animation_started
	main.bg.color = Color(0.582, 0, 0.27)
	main.hitstop(40)
	await main.hitstop_timer.timeout
	if health > 0:
		main.clear_room(true)
		main.intensity_mult = 0.6
		main.new_room(true)

func die() -> void:
	main.show_results()
