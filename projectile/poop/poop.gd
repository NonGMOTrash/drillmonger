extends Projectile

const STARTUP: float = 0.3

@onready var hitbox_cshape: CollisionShape2D = $hitbox/CollisionShape2D

var startup_time: float = STARTUP

func _ready() -> void:
	hitbox_cshape.disabled = true

func _physics_process(delta) -> void:
	startup_time -= delta
	if startup_time <= 0:
		hitbox_cshape.disabled = false
		set_physics_process(false)
