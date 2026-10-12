
extends Node

@export var move_speed: float = 250.0
@export var acceleration: float = 2500.0
@export var friction: float = 1600.0
@export var jump_velocity: float = -450.0
@export var gravity: float = 900.0
@export var fall_gravity_multiplier: float = 1.4
@export var jump_cut_multiplier: float = 0.55
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

@onready var player: CharacterBody2D = get_parent()

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0


func update_movement(delta: float) -> void:
	if player.is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

	if not player.is_on_floor():
		var current_gravity = gravity

		if player.velocity.y > 0.0:
			current_gravity *= fall_gravity_multiplier

		player.velocity.y += current_gravity * delta

	if Input.is_action_just_released("jump") and player.velocity.y < 0.0:
		player.velocity.y *= jump_cut_multiplier

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		player.velocity.y = jump_velocity
		coyote_timer = 0.0
		jump_buffer_timer = 0.0

	var direction: float = Input.get_axis("move_left", "move_right")

	if direction != 0.0:
		player.velocity.x = move_toward(
			player.velocity.x,
			direction * move_speed,
			acceleration * delta
		)
	else:
		player.velocity.x = move_toward(
			player.velocity.x,
			0.0,
			friction * delta
		)
