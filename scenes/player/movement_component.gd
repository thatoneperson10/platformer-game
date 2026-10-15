
extends Node

@export_group("Ground Movement")
@export var move_speed: float = 250.0
@export var ground_acceleration: float = 2800.0
@export var ground_friction: float = 3200.0

@export_group("Air Movement")
@export var air_acceleration: float = 850.0
@export var air_wish_speed: float = 250.0
@export var air_friction: float = 0.0

@export_group("Bunny Hopping")
@export var bhop_boost: float = 70.0
@export var bhop_min_speed: float = 200.0

@export_group("Jumping")
@export var jump_velocity: float = -350.0
@export var jump_cut_multiplier: float = 0.45
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

@export_group("Gravity")
@export var gravity: float = 980.0
@export var fall_gravity_multiplier: float = 1.4
@export var apex_gravity_multiplier: float = 0.75
@export var apex_threshold: float = 50.0
@export var max_fall_speed: float = 550.0

@onready var player: CharacterBody2D = get_parent()

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

func update_movement(delta: float, movement_locked: bool = false) -> void:
	update_timers(delta)

	if movement_locked:
		return

	apply_gravity(delta)

	var jumped: bool = handle_jump()

	handle_jump_cut()
	handle_horizontal_movement(delta, jumped)

func update_timers(delta: float) -> void:
	if player.is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

func apply_gravity(delta: float) -> void:
	if player.is_on_floor():
		return

	var current_gravity: float = gravity

	if player.velocity.y > 0.0:
		current_gravity *= fall_gravity_multiplier
	elif absf(player.velocity.y) < apex_threshold:
		current_gravity *= apex_gravity_multiplier

	player.velocity.y = minf(
		player.velocity.y + current_gravity * delta,
		max_fall_speed
	)

func handle_jump() -> bool:
	if jump_buffer_timer <= 0.0 or coyote_timer <= 0.0:
		return false

	if player.is_on_floor():
		if absf(player.velocity.x) >= bhop_min_speed:
			player.velocity.x += signf(player.velocity.x) * bhop_boost

	player.velocity.y = jump_velocity

	jump_buffer_timer = 0.0
	coyote_timer = 0.0

	return true

func handle_jump_cut() -> void:
	if Input.is_action_just_released("jump"):
		if player.velocity.y < 0.0:
			player.velocity.y *= jump_cut_multiplier

func handle_horizontal_movement(delta: float, jumped: bool) -> void:
	var direction: float = Input.get_axis("move_left", "move_right")
	var grounded: bool = player.is_on_floor() and not jumped

	if grounded:
		handle_ground_movement(direction, delta)
	else:
		handle_air_movement(direction, delta)

func handle_ground_movement(direction: float, delta: float) -> void:
	if direction == 0.0:
		player.velocity.x = move_toward(
			player.velocity.x,
			0.0,
			ground_friction * delta
		)
		return

	player.velocity.x = move_toward(
		player.velocity.x,
		direction * move_speed,
		ground_acceleration * delta
	)

func handle_air_movement(direction: float, delta: float) -> void:
	if direction == 0.0:
		player.velocity.x = move_toward(
			player.velocity.x,
			0.0,
			air_friction * delta
		)
		return

	var current_speed: float = player.velocity.x * direction
	var add_speed: float = air_wish_speed - current_speed

	if add_speed <= 0.0:
		return

	var acceleration_speed: float = minf(
		air_acceleration * delta,
		add_speed
	)

	player.velocity.x += direction * acceleration_speed
