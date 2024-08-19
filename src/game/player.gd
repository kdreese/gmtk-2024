extends CharacterBody2D


@export var SPEED := 150.0
@export var DASH_SPEED := 300.0
@export var MAX_ACCELERATION := 400.0
@export var MAX_AIR_ACCELERATION := 350.0
@export var MAX_DECELERATION := 600.0
@export var MAX_AIR_DECELERATION := 350.0
@export var MAX_TURN_SPEED := 1500.0
@export var MAX_AIR_TURN_SPEED := 1200.0
@export var MAX_DASH_ACCELERATION := 4000.0
@export var MAX_DASH_DECELERATION := 3800.0
@export var MAX_DASH_TIME := 0.2
@export var DASH_COOLDOWN := 0.3
@export var GROUNDED_JUMP_VELOCITY := -300.0
@export var AERIAL_JUMP_VELOCITY := -280.0
@export var JUMP_RELEASE_VELOCITY_REDUCTION := 1.8
@export var COYOTE_TIME_LIMIT := 0.2
@export var LANDING_JUMP_BUFFER_TIME := 0.05


var facing_dir := 1

# Jump variables
@export var unlocked_double_jump := true
var has_used_grounded_jump := false
var has_used_aerial_jump := false		# TODO: Convert to num_aerial_jumps in case we want to allow for more than one
var time_since_was_on_floor := 0.0
var stored_jump_attempt := false
var time_since_stored_jump_attempted := 0.0
var is_jumping_up := false

# Dash variables
@export var unlocked_dash := true
var is_dashing := false
var dash_time := 0.0
var dash_cooldown_timer := 0.0
var is_dash_on_cooldown := false
var has_used_aerial_dash := false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var standing_collision_shape: CollisionShape2D = $StandingCollisionShape
@onready var dashing_collision_shape: CollisionShape2D = $DashingCollisionShape


func _ready() -> void:
	animated_sprite_2d.play("idle")
	if facing_dir == 1:
		animated_sprite_2d.flip_h = true


func _physics_process(delta: float) -> void:
	var acceleration: float
	var deceleration: float
	var turn_speed: float
	var max_speed_change: float

	# Add the gravity.
	if not is_on_floor():
		if not is_dashing:
			velocity += get_gravity() * delta
		time_since_was_on_floor += delta
		acceleration = MAX_AIR_ACCELERATION
		deceleration = MAX_AIR_DECELERATION
		turn_speed = MAX_AIR_TURN_SPEED
		if stored_jump_attempt:
			time_since_stored_jump_attempted += delta
		if sign(velocity.y) == 1:
			animated_sprite_2d.play("jump_descending")
			is_jumping_up = false
	else:
		if animated_sprite_2d.animation == "jump_descending":
			play_step_sound()
			animated_sprite_2d.stop()
		time_since_was_on_floor = 0.0
		has_used_grounded_jump = false
		has_used_aerial_jump = false
		has_used_aerial_dash = false
		is_jumping_up = false
		acceleration = MAX_ACCELERATION
		deceleration = MAX_DECELERATION
		turn_speed = MAX_TURN_SPEED
		if stored_jump_attempt and time_since_stored_jump_attempted < LANDING_JUMP_BUFFER_TIME and not has_used_grounded_jump:
			jump(true)
			has_used_grounded_jump = true
		stored_jump_attempt = false
		time_since_stored_jump_attempted = 0.0

	if is_dash_on_cooldown:
		dash_cooldown_timer += delta
		if dash_cooldown_timer >= DASH_COOLDOWN:
			is_dash_on_cooldown = false
			dash_cooldown_timer = 0.0

	# Handle jump
	var can_ground_jump := is_on_floor() or (was_on_floor() and not has_used_grounded_jump) and not is_dashing
	var can_air_jump := not can_ground_jump and unlocked_double_jump and not has_used_aerial_jump and not is_dashing
	if Input.is_action_just_pressed("jump") and can_ground_jump:
		jump(true)
		has_used_grounded_jump = true
	if Input.is_action_just_pressed("jump") and can_air_jump:
		jump(false)
		has_used_aerial_jump = true
	if Input.is_action_just_pressed("jump") and not (can_ground_jump or can_air_jump):
		stored_jump_attempt = true
	if is_jumping_up and Input.is_action_just_released("jump"):
		velocity.y /= JUMP_RELEASE_VELOCITY_REDUCTION
		is_jumping_up = false

	# Handle dash
	if Input.is_action_just_pressed("dash") and unlocked_dash and not is_dash_on_cooldown and (is_on_floor() or not has_used_aerial_dash):
		is_dashing = true
		velocity = Vector2.ZERO
		$Audio/Dash.play()
		animated_sprite_2d.play("dash")
		if not is_on_floor():
			has_used_aerial_dash = true
		swap_collision_states()

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("move_left", "move_right")
	if sign(direction) != 0:
		facing_dir = sign(direction)
	animated_sprite_2d.flip_h = facing_dir == 1
	if is_dashing:
		dash_time += delta
		if dash_time < MAX_DASH_TIME:
			velocity.x = move_toward(velocity.x, facing_dir * DASH_SPEED, MAX_DASH_ACCELERATION)
		elif absf(velocity.x) > absf(direction) * SPEED:
			velocity.x = move_toward(velocity.x, direction * SPEED, MAX_DASH_DECELERATION)
		else:
			is_dashing = false
			is_dash_on_cooldown = true
			dash_time = 0
			animated_sprite_2d.play("dash_end")
			swap_collision_states()
	else:
		if direction != 0:
			if signf(direction) != signf(velocity.x):
				max_speed_change = turn_speed * delta
			else:
				max_speed_change = acceleration * delta
		else:
			max_speed_change = deceleration * delta
		velocity.x = move_toward(velocity.x, direction * SPEED, max_speed_change)
		if velocity == Vector2.ZERO:
			animated_sprite_2d.play("idle")
		elif not animated_sprite_2d.is_playing() or animated_sprite_2d.animation == "idle":
			animated_sprite_2d.play("walk")

	move_and_slide()


func jump(is_grounded_jump: bool) -> void:
	is_jumping_up = true
	velocity.y = GROUNDED_JUMP_VELOCITY if is_grounded_jump else AERIAL_JUMP_VELOCITY
	animated_sprite_2d.play("jump_ascending")
	$Audio/Jump.play()


func was_on_floor() -> bool:
	return not is_on_floor() and time_since_was_on_floor <= COYOTE_TIME_LIMIT


func on_animation_changed() -> void:
	if $AnimatedSprite2D.animation == "walk":
		play_step_sound()
		$StepTimer.start()
	else:
		$StepTimer.stop()


func play_step_sound() -> void:
	var stream := $Audio/Steps.get_children().pick_random() as AudioStreamPlayer
	stream.play()


func swap_collision_states() -> void:
	if standing_collision_shape.disabled == false:
		dashing_collision_shape.disabled = false
		standing_collision_shape.disabled = true
	else:
		standing_collision_shape.disabled = false
		dashing_collision_shape.disabled = true


func _on_hurt_box_area_entered(area: Area2D) -> void:
	animated_sprite_2d.play("hurt")
	print("area entered")
