extends CharacterBody2D

signal item_picked(type)

@export var speed: int = 100
@export var health: int = 3
@export var dmg: int = 3

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var health_label: Label = $HealthLabel
@onready var state_label: Label = $StateLabel

enum States { Idle, Running, Melee_Attack, Ranged_Attack, Death }
var current_State = States.Idle

var direction: Vector2
var last_flip := 1
var flip_tween: Tween

var is_hurt := false
var hurt_cooldown: float = 0.3

func _ready():
	add_to_group("player")
	current_State = States.Idle

func _process(_delta):
	health_label.text = str(health)
	state_label.text = "State " + str(current_State)

	match current_State:
		States.Idle:
			_idle_state()
		States.Running:
			_running_state()
		States.Melee_Attack:
			pass
		States.Ranged_Attack:
			pass
		States.Death:
			pass

	move_and_slide()

func _idle_state():
	direction = Input.get_vector("left","right","up","down")
	if direction != Vector2.ZERO:
		current_State = States.Running

	if direction.x < 0:
		flip(-1)
	elif direction.x > 0:
		flip(1)

func _running_state():
	_movement()
	if direction == Vector2.ZERO:
		current_State = States.Idle

func _movement():
	direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed

	if velocity.x < 0:
		flip(-1)
	elif velocity.x > 0:
		flip(1)

func flip(dir: int):
	if last_flip == dir:
		return

	last_flip = dir
	var new_scale_x = abs(sprite_2d.scale.x) * dir

	if flip_tween and flip_tween.is_running():
		flip_tween.kill()

	flip_tween = create_tween()
	flip_tween.tween_property(sprite_2d, "scale:x", new_scale_x, 0.1)

func take_damage(amount: int):
	if is_hurt:
		return

	health -= amount
	is_hurt = true

	var blink = create_tween()
	blink.tween_property(sprite_2d, "modulate", Color.RED, 0.1)
	blink.tween_property(sprite_2d, "modulate", Color.WHITE, 0.1)

	await get_tree().create_timer(hurt_cooldown).timeout
	is_hurt = false

	if health <= 0:
		die()

func die():
	queue_free()

func pickup_blood():
	emit_signal("item_picked", "blood")

func pickup_bone():
	emit_signal("item_picked", "bone")
