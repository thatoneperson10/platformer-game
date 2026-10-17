
extends Node

@export_group("Dash")
@export var dash_boost: float = 420.0
@export var minimum_dash_speed: float = 480.0
@export var dash_duration: float = 0.13
@export var max_total_speed: float = 1400.0
@export var max_upward_dash_speed: float = 480.0

@onready var player: CharacterBody2D = get_parent()

var is_dashing: bool = false
var can_dash: bool = true
var dash_ended_this_frame: bool = false

var facing_direction: float = 1.0
var dash_direction: Vector2 = Vector2.RIGHT
var dash_velocity: Vector2 = Vector2.ZERO
var dash_timer: float = 0.0

func update_dash(delta: float) -> void:
	dash_ended_this_frame = false

	if player.is_on_floor() and not is_dashing:
		can_dash = true

	if not is_dashing:
		if Input.is_action_just_pressed("dash") and can_dash:
			start_dash()

	if not is_dashing:
		return

	player.velocity = dash_velocity
	dash_timer -= delta

	if dash_timer <= 0.0:
		finish_dash()

func start_dash() -> void:
	var horizontal: float = Input.get_axis("move_left", "move_right")
	var vertical: float = Input.get_axis("aim_up", "aim_down")

	dash_direction = Vector2(horizontal, vertical).normalized()

	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2(facing_direction, 0.0)

	var current_speed: float = player.velocity.dot(dash_direction)

	var impulse: float = maxf(
		dash_boost,
		minimum_dash_speed - current_speed
	)

	dash_velocity = player.velocity + dash_direction * impulse
	
	if dash_direction.y < 0.0:
		dash_velocity.y = maxf(dash_velocity.y, -max_upward_dash_speed)

	if max_total_speed > 0.0:
		dash_velocity = dash_velocity.limit_length(max_total_speed)

	is_dashing = true
	can_dash = false
	dash_timer = dash_duration

func finish_dash() -> void:
	is_dashing = false
	dash_ended_this_frame = true

	player.velocity = dash_velocity


func cancel_dash() -> void:
	if not is_dashing:
		return

	is_dashing = false
	dash_timer = 0.0
	dash_ended_this_frame = false
	dash_velocity = player.velocity
