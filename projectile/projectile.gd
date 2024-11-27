extends CharacterBody2D
class_name Projectile

const MAP_BORDER: Vector2 = Vector2(640, 360)

@export var speed: float
@export var range: float
@export var damage: int
@export var point_sprite: bool = false
@export var sprite_path: NodePath

var direction: Vector2 = Vector2.ZERO
var distance_traveled: float = 0
var source: Entity

func _ready() -> void:
	if point_sprite:
		get_node(sprite_path).rotation = direction.angle()

func _physics_process(delta: float) -> void:
	velocity = direction * speed
	
	distance_traveled += speed * delta
	if distance_traveled > range:
		queue_free()
	
	move_and_slide()
	
	if global_position.x > MAP_BORDER.x:
		global_position.x = 0
	if global_position.x < 0:
		global_position.x = MAP_BORDER.x
	
	if global_position.y > MAP_BORDER.y:
		global_position.y = 0
	if global_position.y < 0:
		global_position.y = MAP_BORDER.y

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.get_parent() == source and distance_traveled < 20 or area.monitorable == false:
		return
	else:
		queue_free()
