extends Entity
class_name Player

const PARTICLE_PARRY: PackedScene = preload("res://effects/particle_parry.tscn")
const SFX_PARRY: PackedScene = preload("res://sounds/parry.tscn")

const DASH_COOLDOWN: float = 0.01
const DASH_STRENGTH: float = 1000.0
const PARRY_WINDOW_PROJECITLE: float = 0.016
const PARRY_WINDOW_MELEE: float = 0.05
const PARRY_LOCKOUT: float = 0.1
const PARRY_INVULN_TIME: float = 0.07
const CROSSOVER_INVULN_TIME: float = 0.15
const HIT_INVULN_TIME: float = 0.05
const DAMAGE: int = 1
const HIT_KNOCKBACK: float = 700.0

@onready var hitbox: Area2D = $hitbox
@onready var hitbox_cshape: CollisionShape2D = $hitbox/CollisionShape2D
@onready var hurtbox: Area2D = $hurtbox
@onready var parrybox: Area2D = $parrybox
@onready var parrybox_cshape: CollisionShape2D = $parrybox/CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var sprite_animation: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var main: Main = get_parent()

const PARRY_WINDOW_MAX: float = max(PARRY_WINDOW_PROJECITLE, PARRY_WINDOW_MELEE)

var cooldown_dash: float = 0
var stored_direction: Vector2 = Vector2.DOWN
var parrying_time: float = 0
var parrying_lockout: float = 0
var parry_success: bool = false
var invuln_time: float = 0
var recent_crossovers: int = 0 # counts the crossovers in the last second to prevent cheesing with the invuln
var crossover_reset_time: float = 1.0
var sprite_old_frame: int = 0

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
				var offset: float = parrybox_cshape.shape.radius
				parrybox.position = velocity.normalized() * offset  + Vector2(0, 6)
				parrying_time = PARRY_WINDOW_MAX
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
	
	if velocity.length() > 450:
		sprite_old_frame = sprite.frame
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
			sprite_animation.stop()
			if abs(stored_direction.x) > abs(stored_direction.y):
				sprite.frame = 4
			elif stored_direction.y < 0:
				sprite.frame = 8
			else:
				sprite.frame = 0

	if direction.x > 0:
		sprite.flip_h = false
	elif direction.x < 0:
		sprite.flip_h = true
	
	if hurtbox.monitoring == false and invuln_time > 0:
		invuln_time -= delta
		if invuln_time <= 0:
			hurtbox.monitoring = true
	
	crossover_reset_time -= delta
	if crossover_reset_time <= 0:
		crossover_reset_time = 2.0
		recent_crossovers = 0
	
	super._physics_process(delta)

func _on_parrybox_area_entered(area: Area2D) -> void:
	var area_parent: Node = area.get_parent()
	if invuln_time > 0 or area_parent == self:
		return
	
	#prints("projectile time: " PARRY_WINDOW_MAX - parrying_time)
	#prints("melee time     : ", )
	if area_parent is Projectile and parrying_time >= PARRY_WINDOW_MAX - PARRY_WINDOW_PROJECITLE:
		var projectile: Projectile = area_parent
		projectile.queue_free()
	elif area_parent is Entity and parrying_time >= PARRY_WINDOW_MAX - PARRY_WINDOW_MELEE:
		pass
	else:
		return
	
	animation.play("parry")
	main.hitstop(3)
	
	var sound: Sound = SFX_PARRY.instantiate()
	get_tree().current_scene.add_child(sound)
	
	var particle: Particle = PARTICLE_PARRY.instantiate()
	particle.global_position = global_position
	get_tree().current_scene.add_child(particle)
	
	if main.room_time <= main.room_time_expected:
		main.room_time -= 0.5
		main.hud_animation.play("parry")
	
	start_invuln(PARRY_INVULN_TIME)
	parrying_time = 0
	parrying_lockout = 0
	cooldown_dash = 0
	parry_success = true

	for overlapping_hitbox in parrybox.get_overlapping_areas():
			if overlapping_hitbox.get_parent() is Projectile:
				overlapping_hitbox.get_parent().queue_free()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.get_parent() is Entity and area.get_parent() != self:
		velocity = -global_position.direction_to(area.get_parent().global_position).normalized() * HIT_KNOCKBACK
		main.hitstop(4)
		start_invuln(HIT_INVULN_TIME)

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
		main.intensity_mult = 0.5
		main.new_room()

func _on_crossed_map_border() -> void:
	recent_crossovers += 1
	if recent_crossovers < 5:
		start_invuln(CROSSOVER_INVULN_TIME)

func die() -> void:
	main.show_results()

func start_invuln(duration: float) -> void:
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	invuln_time = duration
