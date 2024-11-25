extends Node
class_name Main

const CANNON: PackedScene = preload("res://entity/cannon/cannon.tscn")
const MAGE: PackedScene = preload("res://entity/mage/mage.tscn")

@onready var player: Player = $player
@onready var room: Node = $room
@onready var room_number: Label = $anchor/room_number
@onready var room_number_animation: AnimationPlayer = $anchor/room_number/AnimationPlayer
@onready var bg: ColorRect = $bg
@onready var bg_animation: AnimationPlayer = $bg/AnimationPlayer
@onready var timer_label: Label = $timer_label
@onready var quick_clear_animation: AnimationPlayer = $quick_clear/AnimationPlayer
@onready var results_rooms_cleared: Label = $results/VBoxContainer/rooms_cleared
@onready var results_animation: AnimationPlayer = $results/AnimationPlayer
@onready var results_button_again: Button = $results/VBoxContainer/again
@onready var music: AudioStreamPlayer = $music

enum ENEMY_TYPES {
	CANNON,
	MAGE
}

var rooms_cleared: int = 0
var intensity_mult: float = 1.0
var difficulty_savings: float = 0
var enemy_count: int = 0
var enemies_left: int = 0
var room_time: float = 0
var room_time_expected: float = 0

func _ready() -> void:
	new_room()

func _physics_process(delta: float) -> void:
	room_time += delta
	
	var time: float = room_time_expected - room_time
	var minutes: int = time / 60
	var seconds: int = fmod(time, 60)
	var miliseconds: int = fmod(time, 1) * 100
	timer_label.text = ""
	if time > 0:
		if minutes < 10:
			timer_label.text += "0"
		timer_label.text += str(minutes) + ":"
		if seconds < 10:
			timer_label.text += "0"
		timer_label.text += str(seconds) + ":"
		if miliseconds < 10:
			timer_label.text += "0"
		timer_label.text += str(miliseconds)
	
	if get_tree().paused:
		music.pitch_scale = 0.1
	else:
		music.pitch_scale = 1.0

func clear_room(was_hit: bool = false):
	if not was_hit:
		player.hitstop(6)
	
	if was_hit:
		bg_animation.play("flash_red")
	else:
		bg_animation.play("flash_orange")
	
	for child in room.get_children():
		if child is Entity and child.is_connected("tree_exiting", on_enemy_killed):
			child.disconnect("tree_exiting", on_enemy_killed)
		child.queue_free()
	
	enemies_left = 0
	enemy_count = 0
	
	if room_time < room_time_expected and not was_hit:
		quick_clear_animation.play("quick_clear")
		player.health += 1
	room_time = 0
	room_time_expected = 0

func new_room(was_hit: bool = false):
	clear_room(was_hit)
	room_number.text = str(rooms_cleared+1)
	room_number_animation.play("popup")
	
	var difficulty_budget: float = max(rooms_cleared * intensity_mult + difficulty_savings, 1.0)
	difficulty_savings = 0
	
	while true:
		
		var enemy: Entity = null
		var count: int = 1
		var cost: float
		var expected_time: float
		
		while true:
			match (randi() % 2):
				ENEMY_TYPES.CANNON:
					enemy = CANNON.instantiate() as Cannon
					cost = 1.0
					expected_time = 0.92
				ENEMY_TYPES.MAGE:
					enemy = MAGE.instantiate() as Mage
					cost = 4.5
					expected_time = 2.5
			if cost <= difficulty_budget or difficulty_budget < 1.0:
				break #                           cheapest cost /\
		
		if enemy:
			count = randi_range( 1, min(floor(difficulty_budget/cost),20) )
			cost *= count
			expected_time *= count
		
			for i in count:
				var new_enemy: Entity = enemy.duplicate()
				new_enemy.global_position = Vector2(randf_range(0,640), randf_range(0,360))
				room.call_deferred("add_child", new_enemy)
				
				enemies_left += 1
				new_enemy.connect("tree_exiting", on_enemy_killed)
		
		room_time_expected += expected_time
		difficulty_budget -= cost
		if difficulty_budget <= 1.0:
			difficulty_savings = abs(difficulty_budget)
			break
	
	enemy_count = enemies_left
	room_time_expected = pow(room_time_expected, 1.2)

func on_enemy_killed() -> void:
	bg_animation.play("flash_orange_quick")
	enemies_left -= 1
	
	if enemies_left == 0:
		rooms_cleared += 1
		if intensity_mult >= 1.4:
			intensity_mult = 0.6
		else:
			intensity_mult += 0.2
		
		new_room(false)

func show_results() -> void:
	#process_mode = PROCESS_MODE_ALWAYS
	#room.process_mode = PROCESS_MODE_PAUSABLE
	get_tree().paused = true
	
	if rooms_cleared == 1:
		results_rooms_cleared.text = "cleared 1 room"
	else:
		results_rooms_cleared.text = "cleared %s rooms" % rooms_cleared
	results_animation.play("appear")
	results_button_again.grab_focus()
	
func _on_again_pressed() -> void:
	if not results_animation.is_playing():
		get_tree().paused = false
		get_tree().reload_current_scene()

func _on_title_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://title/title.tscn")