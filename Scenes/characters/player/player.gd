extends CharacterBody2D

@export var speed  : int = 100
@export var health : int = 3
@export var dmg    : int = 3

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var health_label: Label = $HealthLabel
@onready var state_label: Label = $StateLabel

enum States { Idle, Running, Melee_Attack, Ranged_Attack, Death }
var current_State = States.Idle

var direction : Vector2


# Flip system
var last_flip := 1   # 1 = right, -1 = left
var flip_tween : Tween

# Idle jiggle system
var idle_tween : Tween
var idle_playing := false

var is_hurt := false
var hurt_cooldown: float = 0.3


func _ready() -> void:
	current_State = States.Idle


func _process(_delta: float) -> void:
	health_label.text = str(health)
	state_label.text = "State " + str(current_State)
	
	match current_State:
		States.Idle:
			_idle_state()
		States.Running:
			_running_state()
		States.Melee_Attack:
			print("attacking")
		States.Ranged_Attack:
			print("shooting")
		States.Death:
			print("dying")

	move_and_slide()


# ------------------------
# IDLE STATE
# ------------------------
func _idle_state():
	# Get input
	direction = Input.get_vector("left","right","up","down")
	if direction != Vector2.ZERO:
		current_State = States.Running

	# Flip while idle if needed
	if direction.x < 0:
		flip(-1)
	elif direction.x > 0:
		flip(1)

	# Play idle jiggle once per loop
	if idle_playing:
		return

	idle_playing = true
	#idle_tween = create_tween()
	## Only jiggle vertically to avoid conflict with scale.x flip
	#idle_tween.tween_property(sprite_2d, "scale:y", 0.95, 0.25)
	#idle_tween.tween_property(sprite_2d, "scale:y", 1.0, 0.25)
	#idle_tween.finished.connect(func():
		#idle_playing = false)


# ------------------------
# RUNNING STATE
# ------------------------
func _running_state():
	_movement()
	if direction == Vector2.ZERO:
		current_State = States.Idle


# ------------------------
# MOVEMENT FUNCTION
# ------------------------
func _movement():
	direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed

	# Flip based on movement
	if velocity.x < 0:
		flip(-1)
	elif velocity.x > 0:
		flip(1)

func die():
	print("Player died!")
	queue_free()
	pass

# ------------------------
# FLIP FUNCTION
# ------------------------
func flip(target_x):
	if last_flip == target_x:
		return  # already facing this way

	last_flip = target_x
	
	target_x = target_x * sprite_2d.scale.x

	# Smooth flip tween
	if flip_tween and flip_tween.is_running():
		flip_tween.kill()  # stop previous tween if any

	flip_tween = create_tween()
	flip_tween.tween_property(sprite_2d, "scale:x", target_x, 0.1)

func take_damage(amount: int):
	if is_hurt:
		return

	health -= amount
	is_hurt = true
	print("Player took", amount, "damage! Now:", health)

	var blink = create_tween()
	blink.tween_property(sprite_2d, "modulate", Color.RED, 0.1)
	blink.tween_property(sprite_2d, "modulate", Color.WHITE, 0.1)

	await get_tree().create_timer(hurt_cooldown).timeout
	is_hurt = false

	if health <= 0:
		die()
