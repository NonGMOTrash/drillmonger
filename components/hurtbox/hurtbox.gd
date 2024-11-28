extends Area2D
class_name Hurtbox

const PARTICLE_HIT: PackedScene = preload("res://effects/particle_hit.tscn")
const COLOR_ORANGE: Color = Color(1, 0.483, 0)
const COLOR_PINK: Color = Color(1, 0, 0.533)

@export var sfx_onhit: PackedScene

@onready var parent: Entity = get_parent()

signal was_hit(from_pos: Vector2)

func _on_area_entered(area: Area2D) -> void:
	var hitbox_parent: Node = area.get_parent()
	
	if (
		(hitbox_parent == parent) or
		(hitbox_parent is Projectile and hitbox_parent.source == parent and hitbox_parent.distance_traveled < 20)
	):
		return
	elif hitbox_parent is Projectile:
		var projectile: Projectile = hitbox_parent
		parent.health -= projectile.damage
		was_hit.emit(projectile.global_position)
		
		var particle: Particle = PARTICLE_HIT.instantiate()
		particle.modulate = COLOR_PINK
		particle.global_position = global_position
		particle.rotation = global_position.direction_to(projectile.global_position).angle()
		get_tree().current_scene.add_child(particle)
		
		var sound: Sound = sfx_onhit.instantiate()
		get_tree().current_scene.add_child(sound)
	elif hitbox_parent is Entity:
		var entity: Entity = hitbox_parent
		parent.health -= entity.damage
		parent.velocity -= parent.global_position.direction_to(entity.global_position).normalized() * 325.0
		was_hit.emit(entity.global_position)
		
		var particle: Particle = PARTICLE_HIT.instantiate()
		if entity is Player:
			particle.modulate = COLOR_ORANGE
		else:
			particle.modulate = COLOR_PINK
		particle.global_position = global_position
		particle.rotation = global_position.direction_to(entity.global_position).angle()
		get_tree().current_scene.add_child(particle)
		
		var sound: Sound = sfx_onhit.instantiate()
		get_tree().current_scene.add_child(sound)

	if parent.health <= 0:
		parent.die()
