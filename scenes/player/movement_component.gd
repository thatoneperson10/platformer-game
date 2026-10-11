extends Node

@export var move_speed: float = 250.0
@export var jump_velocity: float = -350.0
@export var gravity: float = 980.0

@onready var player: CharacterBody2D = get_parent()

func update_movement(delta: float) -> void:
	if not player.is_on_floor():
		player.velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		player.velocity.y = jump_velocity

	var direction = Input.get_axis("move_left", "move_right")
	player.velocity.x = direction * move_speed
