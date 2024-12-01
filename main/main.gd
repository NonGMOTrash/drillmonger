extends Node
class_name Main

const CANNON: PackedScene = preload("res://entity/cannon/cannon.tscn")
const MAGE: PackedScene = preload("res://entity/mage/mage.tscn")
const SLIME: PackedScene = preload("res://entity/slime/slime.tscn")
const TOTEM: PackedScene = preload("res://entity/totem/totem.tscn")
const TURRET: PackedScene = preload("res://entity/turret/turret.tscn")

@onready var player: Player = $player
@onready var room: Node = $room
@onready var room_number: Label = $anchor/room_number
@onready var room_number_animation: AnimationPlayer = $anchor/room_number/AnimationPlayer
@onready var bg: ColorRect = $bg
@onready var bg_animation: AnimationPlayer = $bg/AnimationPlayer
@onready var hud: VBoxContainer = $HUD
@onready var hud_timer_label: Label = $HUD/timer_label
@onready var hud_animation: AnimationPlayer = $HUD/AnimationPlayer
@onready var hud_health: Label = $HUD/HBoxContainer/health
@onready var paused_overlay: ColorRect = $paused_overlay
@onready var results_rooms_cleared: Label = $results/VBoxContainer/rooms_cleared
@onready var results_animation: AnimationPlayer = $results/AnimationPlayer
@onready var results_button_again: Button = $results/VBoxContainer/again
@onready var music: AudioStreamPlayer = $music
@onready var hitstop_timer: Timer = $hitstop_timer

enum ENEMY_TYPES {
	CANNON,
	MAGE,
	SLIME,
	TOTEM,
	TURRET
}

var rooms_cleared: int = 0
var intensity_mult: float = 1.0
var difficulty_savings: float = 0
var enemy_count: int = 0
var enemies_left: int = 0
var room_time: float = 0
var room_time_expected: float = 0
var game_paused: bool = false

func _ready() -> void:
	new_room()

func _physics_process(delta: float) -> void: #     \ can't pause during hitstop    /
	if Input.is_action_just_pressed("pause") and !(get_tree().paused and !game_paused):
		game_paused = !game_paused
		get_tree().paused = game_paused
		paused_overlay.visible = game_paused
		room_time = 999
		hud_timer_label.text = ""
	
	if get_tree().paused:
		music.pitch_scale = 0.5
	else:
		music.pitch_scale = 1.0
	
	if game_paused:
		return
	
	room_time += delta
	
	var time: float = room_time_expected - room_time
	var minutes: int = time / 60.0
	var seconds: int = fmod(time, 60.0)
	var miliseconds: int = fmod(time, 1) * 100.0
	hud_timer_label.text = ""
	if time > 0:
		if minutes < 10:
			hud_timer_label.text += "0"
		hud_timer_label.text += str(minutes) + ":"
		if seconds < 10:
			hud_timer_label.text += "0"
		hud_timer_label.text += str(seconds) + ":"
		if miliseconds < 10:
			hud_timer_label.text += "0"
		hud_timer_label.text += str(miliseconds)

func clear_room(was_hit: bool = false):
	if not was_hit:
		hitstop(8)
		player.start_invuln(0.25)
	
	if was_hit:
		bg_animation.play("flash_red")
	else:
		bg_animation.play("flash_orange")
	
	for child in room.get_children():
		#if child is Entity and child.is_connected("death", on_enemy_death):
			#child.disconnect("death", on_enemy_death)
		child.queue_free()
	
	enemies_left = 0
	enemy_count = 0
	
	if room_time < room_time_expected and not was_hit:
		hud_animation.play("quick_clear")
		player.health += 1
	room_time = 0
	room_time_expected = 0

func new_room():
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
			match (randi() % 5):
				ENEMY_TYPES.CANNON:
					enemy = CANNON.instantiate() as Cannon
					cost = 1.0
					expected_time = 0.96
				ENEMY_TYPES.MAGE:
					enemy = MAGE.instantiate() as Mage
					cost = 5.5
					expected_time = 2.23
				ENEMY_TYPES.SLIME:
					enemy = SLIME.instantiate() as Slime
					cost = 1.9
					expected_time = 1.3
				ENEMY_TYPES.TOTEM:
					enemy = TOTEM.instantiate() as Totem
					cost = 13
					expected_time = 7.5
				ENEMY_TYPES.TURRET:
					enemy = TURRET.instantiate() as Turret
					cost = 1.0
					expected_time = 0.68
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
				new_enemy.connect("death", on_enemy_death)
		
		room_time_expected += expected_time
		difficulty_budget -= cost
		if difficulty_budget <= 1.0:
			difficulty_savings = abs(difficulty_budget)
			break
	
	enemy_count = enemies_left
	room_time_expected = pow(room_time_expected, 0.89)

func on_enemy_death() -> void:
	bg_animation.play("flash_orange_quick")
	enemies_left -= 1
	
	if enemies_left == 0:
		rooms_cleared += 1
		if intensity_mult >= 1.8:
			intensity_mult = 0.5
		else:
			intensity_mult += 0.1
			if room_time <= room_time_expected:
				intensity_mult += 0.15
		
		clear_room(false)
		new_room()

func show_results() -> void:
	#process_mode = PROCESS_MODE_ALWAYS
	#room.process_mode = PROCESS_MODE_PAUSABLE
	hitstop_timer.process_mode = Node.PROCESS_MODE_DISABLED
	hud.visible = false
	music.pitch_scale = 0.5
	get_tree().paused = true
	
	if rooms_cleared == 1:
		results_rooms_cleared.text = "cleared 1 room"
	else:
		results_rooms_cleared.text = "cleared %s rooms" % rooms_cleared
	results_animation.play("appear")
	results_button_again.grab_focus()

func hitstop(frames: int) -> void:
	hitstop_timer.wait_time = (frames as float)/60.0
	hitstop_timer.start()
	get_tree().paused = true

func _on_again_pressed() -> void:
	if not results_animation.is_playing():
		get_tree().paused = false
		get_tree().reload_current_scene()

func _on_title_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://title/title.tscn")

func _on_hitstop_timer_timeout() -> void:
	get_tree().paused = false
