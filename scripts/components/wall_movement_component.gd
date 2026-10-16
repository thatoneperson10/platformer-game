
extends Node

@export_group("Wall Sliding")
@export var wall_slide_speed: float = 90.0
@export var require_wall_input: bool = true

@export_group("Wall Jumping")
@export var wall_jump_horizontal_speed: float = 300.0
@export var wall_jump_vertical_speed: float = 350.0
@export var momentum_retention: float = 0.85
@export var wall_jump_control_lock: float = 0.12

@onready var player: CharacterBody2D = get_parent()

var is_wall_sliding: bool = false
var wall_jump_lock_timer: float = 0.0
var wall_jump_direction: float = 0.0

func update_wall_movement(delta: float, dash_locked: bool, movement: Node) -> void:
	is_wall_sliding = false
	wall_jump_lock_timer = maxf(wall_jump_lock_timer - delta, 0.0)

	if dash_locked:
		return

	if player.is_on_floor():
		return

	if not player.is_on_wall():
		return

	var normal: Vector2 = player.get_wall_normal()

	if absf(normal.x) < 0.5:
		return

	var input_direction: float = Input.get_axis("move_left", "move_right")
	var pressing_toward_wall: bool = input_direction * normal.x < 0.0

	if Input.is_action_just_pressed("jump") and movement.coyote_timer <= 0.0:
		start_wall_jump(normal, movement)
		return

	if wall_jump_lock_timer > 0.0:
		return

	if require_wall_input and not pressing_toward_wall:
		return

	if player.velocity.y > 0.0:
		is_wall_sliding = true
		player.velocity.y = minf(player.velocity.y, wall_slide_speed)

func start_wall_jump(normal: Vector2, movement: Node) -> void:
	wall_jump_direction = signf(normal.x)

	var existing_away_speed: float = player.velocity.x * wall_jump_direction

	var launch_speed: float = maxf(
		wall_jump_horizontal_speed,
		existing_away_speed * momentum_retention
	)

	player.velocity.x = wall_jump_direction * launch_speed
	player.velocity.y = -wall_jump_vertical_speed

	wall_jump_lock_timer = wall_jump_control_lock
	is_wall_sliding = false

	movement.jump_buffer_timer = 0.0
	movement.coyote_timer = 0.0

func is_horizontal_locked() -> bool:
	return wall_jump_lock_timer > 0.0
