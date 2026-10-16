
extends Node

signal slam_impact(position: Vector2)

@export_group("Slam")
@export var startup_time: float = 0.06
@export var slam_speed: float = 300.0
@export var slam_acceleration: float = 8000.0
@export var max_slam_speed: float = 4000.0
@export var landing_horizontal_multiplier: float = 1.0

@export_group("Air Control")
@export var slam_air_acceleration: float = 450.0
@export var slam_air_wish_speed: float = 250.0

@onready var player: CharacterBody2D = get_parent()

var is_slamming: bool = false
var is_starting: bool = false
var can_slam: bool = true
var startup_timer: float = 0.0

func update_slam(delta: float, dash_active: bool) -> void:
	if player.is_on_floor() and not is_slamming:
		can_slam = true

	if not is_slamming:
		if not dash_active and not player.is_on_floor():
			if can_slam and Input.is_action_just_pressed("slam"):
				start_slam()

	if not is_slamming:
		return

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

func start_slam() -> void:
	is_slamming = true
	is_starting = true
	can_slam = false
	startup_timer = startup_time

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
	is_slamming = false
	is_starting = false

	player.velocity.x *= landing_horizontal_multiplier
	player.velocity.y = 0.0

	slam_impact.emit(player.global_position)
