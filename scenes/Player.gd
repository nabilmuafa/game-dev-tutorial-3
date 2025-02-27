extends CharacterBody2D

@onready var anim = $AnimatedSprite2D

@export var jump_height : float
@export var jump_time_to_peak : float
@export var jump_time_to_descent : float

@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1

@export var walk_speed = 300
@export var dash_speed = 1500
@export var dash_duration = 0.5

var jump_count = 0

var run_tap_interval = 0.10
var last_tap_time = 0
var last_direction = 0
var is_dashing = false
var dash_timer = 0.0

func _physics_process(delta):
	var direction = Vector2.ZERO
	
	if not is_on_floor():
		velocity.y += get_custom_gravity() * delta
	else:
		jump_count = 0
	
	if jump_count < 2 and Input.is_action_just_pressed('ui_up'):
		velocity.y = jump_velocity
		jump_count += 1
	
	if Input.is_action_pressed("ui_left"):
		direction.x += -1
	elif Input.is_action_pressed("ui_right"):
		direction.x += 1
	
	if Input.is_action_just_pressed("ui_left"):
		anim.flip_h = false
		if Input.is_action_just_pressed("ui_left") and \
		Time.get_ticks_msec() / 1000 - last_tap_time < run_tap_interval and \
		direction.x == last_direction:
			start_dash(-1)
		last_tap_time = Time.get_ticks_msec() / 1000
		last_direction = -1
	
	elif Input.is_action_just_pressed("ui_right"):
		anim.flip_h = true
		if Input.is_action_just_pressed("ui_right") and \
		Time.get_ticks_msec() / 1000 - last_tap_time < run_tap_interval and \
		direction.x == last_direction:
			start_dash(1)
		last_tap_time = Time.get_ticks_msec() / 1000
		last_direction = 1
	
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
		else:
			velocity.x = lerp(velocity.x, walk_speed * direction.x, 5 * delta)
	else:
		if direction != Vector2.ZERO:
			anim.play("walk")
			velocity.x = walk_speed * direction.x
		else:
			anim.play("idle")
			velocity.x = 0
		
	move_and_slide()
	
func start_dash(dir):
	is_dashing = true
	dash_timer = dash_duration
	velocity.x = dash_speed * dir

func get_custom_gravity() -> float:
	return jump_gravity if velocity.y > 0.0 else fall_gravity

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim.play("idle")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
