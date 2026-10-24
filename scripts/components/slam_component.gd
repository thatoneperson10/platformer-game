
extends Node

signal slam_impact(position: Vector2)
signal slam_bounce(position: Vector2)

@export_group("Slam")
@export var startup_time: float = 0.06
@export var slam_speed: float = 1200.0
@export var slam_acceleration: float = 5000.0
@export var max_slam_speed: float = 4000.0
@export var landing_horizontal_multiplier: float = 1.0

@export_group("Air Control")
@export var slam_air_acceleration: float = 450.0
@export var slam_air_wish_speed: float = 250.0

@export_group("Slam Bounce")
@export var bounce_enabled: bool = true
@export var bounce_buffer_time: float = 0.15
@export var bounce_base_speed: float = 350.0
@export var bounce_speed_multiplier: float = 0.25
@export var max_bounce_speed: float = 700.0
@export var minimum_impact_speed: float = 400.0

@onready var player: CharacterBody2D = get_parent()
@onready var movement = player.get_node("MovementComponent")

var is_slamming: bool = false
var is_starting: bool = false
var can_slam: bool = true
var startup_timer: float = 0.0

var bounce_timer: float = 0.0
var bounce_armed: bool = false
var impact_speed: float = 0.0

func update_slam(delta: float, dash_active: bool) -> void:
	if player.is_on_floor() and not is_slamming:
		can_slam = true

	if not is_slamming:
		if not dash_active and not player.is_on_floor():
			if can_slam and Input.is_action_just_pressed("slam"):
				start_slam()

	if not is_slamming:
		return

	update_bounce_input(delta)

	if is_starting:
		startup_timer -= delta
		player.velocity.y = 0.0

		if startup_timer <= 0.0:
			is_starting = false
	else:
		player.velocity.y = minf(
			maxf(player.velocity.y, slam_speed) + slam_acceleration * delta,
			max_slam_speed
		)

	apply_horizontal_control(delta)

	impact_speed = maxf(player.velocity.y, 0.0)

func start_slam() -> void:
	is_slamming = true
	is_starting = true
	can_slam = false
	startup_timer = startup_time

	bounce_timer = 0.0
	bounce_armed = false
	impact_speed = 0.0

func update_bounce_input(delta: float) -> void:
	if not bounce_enabled:
		bounce_armed = false
		bounce_timer = 0.0
		return

	if Input.is_action_pressed("jump"):
		bounce_armed = true
		bounce_timer = bounce_buffer_time
	elif bounce_armed:
		bounce_timer = maxf(bounce_timer - delta, 0.0)

		if bounce_timer <= 0.0:
			bounce_armed = false

func apply_horizontal_control(delta: float) -> void:
	var direction: float = Input.get_axis("move_left", "move_right")

	if direction == 0.0:
		return

	var current_speed: float = player.velocity.x * direction
	var add_speed: float = slam_air_wish_speed - current_speed

	if add_speed <= 0.0:
		return

	var acceleration_speed: float = minf(
		slam_air_acceleration * delta,
		add_speed
	)

	player.velocity.x += direction * acceleration_speed

func after_move() -> void:
	if not is_slamming:
		return

	if player.is_on_floor():
		finish_slam()

func finish_slam() -> void:
	var should_bounce: bool = (
		bounce_enabled
		and bounce_armed
		and bounce_timer > 0.0
		and impact_speed >= minimum_impact_speed
	)

	is_slamming = false
	is_starting = false
	startup_timer = 0.0

	player.velocity.x *= landing_horizontal_multiplier
	player.velocity.y = 0.0

	slam_impact.emit(player.global_position)

	if should_bounce:
		perform_bounce()

	bounce_timer = 0.0
	bounce_armed = false
	impact_speed = 0.0

func perform_bounce() -> void:
	var bounce_speed: float = clampf(
		bounce_base_speed + impact_speed * bounce_speed_multiplier,
		0.0,
		max_bounce_speed
	)

	player.velocity.y = -bounce_speed

	movement.jump_buffer_timer = 0.0
	movement.coyote_timer = 0.0

	slam_bounce.emit(player.global_position)

func cancel_slam() -> void:
	if not is_slamming:
		return

	is_slamming = false
	is_starting = false
	startup_timer = 0.0
	bounce_timer = 0.0
	bounce_armed = false
	impact_speed = 0.0
