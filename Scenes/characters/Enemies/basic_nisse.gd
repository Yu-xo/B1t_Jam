extends CharacterBody2D

signal is_dead

@export var move_speed: float = 60.0
@export var attack_damage := 1
@export var attack_interval := 2.0

@export var health: int = 1
var is_hurt := false
var hurt_cooldown := 0.1

@export var blood_drop_scene: PackedScene
@export var bone_drop_scene: PackedScene

@onready var player: CharacterBody2D = $"../../Player"
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_area: Area2D = $AttackArea

var state := "CHASE"
var attack_cooldown := false


func _process(delta):
	if GameData.wave_paused:
		return  # stop enemy AI but do NOT pause physics signals
	
	animation_player.play("idle")
	match state:
		"CHASE":
			_process_chase(delta)
		"ATTACK":
			_process_attack()


func _process_chase(_delta):
	if not player:
		return
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()


func _process_attack():
	if attack_cooldown:
		return
	if player == null:
		return

	player.take_damage(attack_damage, self)
	attack_cooldown = true
	await get_tree().create_timer(attack_interval).timeout
	attack_cooldown = false


func _on_attack_area_entered(body):
	if body == player:
		state = "ATTACK"

func _on_attack_area_exited(body):
	if body == player:
		state = "CHASE"


# ------------------------------
# DAMAGE + DEATH
# ------------------------------
func take_damage(amount: int, from: Node2D = null):
	if is_hurt:
		return

	health -= amount
	is_hurt = true

	# hit flash
	var t = create_tween()
	t.tween_property(sprite, "modulate", Color(1,0,0), 0.1)
	t.tween_property(sprite, "modulate", Color(1,1,1), 0.1)

	await get_tree().create_timer(hurt_cooldown).timeout
	is_hurt = false

	if health <= 0:
		die()


func die():
	print("Enemy die() called")
	emit_signal("is_dead")     
	_spawn_drop()
	queue_free()


func _spawn_drop():
	print("Drop function triggered!")

	var scene_to_spawn: PackedScene = null
	if randi() % 2 == 0:
		scene_to_spawn = blood_drop_scene
	else:
		scene_to_spawn = bone_drop_scene

	if scene_to_spawn == null:
		push_error("Drop scene not assigned!")
		return

	var drop = scene_to_spawn.instantiate()
	get_parent().add_child(drop)
	drop.global_position = global_position
	print("Drop spawned at:", drop.global_position)
