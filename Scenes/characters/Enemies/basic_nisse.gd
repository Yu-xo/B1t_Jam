extends CharacterBody2D

@export var move_speed: float = 60.0
@onready var player: CharacterBody2D = $"../../Player"
@onready var idle_label: Label = $IdleLabel
@onready var attack_area: Area2D = $AttackArea

@export var attack_damage := 1
@export var attack_interval := 2.0

signal is_dead

var state := "CHASE"
var attack_cooldown := false

func _process(delta: float):
	idle_label.text = state

	match state:
		"CHASE":
			_process_chase(delta)
		"ATTACK":
			_process_attack()

func _process_chase(_delta):
	if not player:
		return

	var direction = (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

func _process_attack():
	if attack_cooldown:
		return

	if player == null:
		return

	player.take_damage(attack_damage)

	attack_cooldown = true

	await get_tree().create_timer(attack_interval).timeout
	attack_cooldown = false

func _on_attack_area_entered(body):
	if body == player:
		state = "ATTACK"

func _on_attack_area_exited(body):
	if body == player:
		state = "CHASE"

func die():
	emit_signal("is_dead")
	queue_free()
