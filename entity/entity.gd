extends CharacterBody2D
class_name Entity

const MAP_BORDER: Vector2 = Vector2(640, 360)

@export var accel: float = 120.00 * 60.0
var slow_down: float = 120 * 60.0
var top_speed: float = 700.0

var direction: Vector2
var health: int = 3
var damage: int = 1

func _physics_process(delta: float) -> void:
	if direction != Vector2.ZERO:
		if velocity.x < top_speed and velocity.x > -top_speed:
			velocity.x += direction.normalized().x * accel * delta
		if velocity.y < top_speed and velocity.y > -top_speed:
			velocity.y += direction.normalized().y * accel * delta
	if direction == Vector2.ZERO or velocity.length() > top_speed:
		velocity = velocity.move_toward(Vector2.ZERO, slow_down * delta)
	
	move_and_slide()
	
	if global_position.x > MAP_BORDER.x:
		global_position.x = 0
	if global_position.x < 0:
		global_position.x = MAP_BORDER.x
	
	if global_position.y > MAP_BORDER.y:
		global_position.y = 0
	if global_position.y < 0:
		global_position.y = MAP_BORDER.y

func die() -> void:
	queue_free()
