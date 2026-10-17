extends Node

@export_group("Run Animation")
@export var reference_run_speed: float = 250.0
@export var minimum_run_scale: float = 0.6
@export var maximum_run_scale: float = 2.0
@export var run_animation_threshold: float = 10.0

@onready var player: CharacterBody2D = get_parent()
@onready var sprite: AnimatedSprite2D = player.get_node("AnimatedSprite2D")
@onready var dash = player.get_node("DashComponent")
@onready var slam = player.get_node("SlamComponent")
@onready var wall = player.get_node("WallMovementComponent")
@onready var grapple = player.get_node("GrappleComponent")

func update_animation() -> void:
	var horizontal: float = Input.get_axis("move_left", "move_right")

	if horizontal > 0.0:
		sprite.flip_h = true
	elif horizontal < 0.0:
		sprite.flip_h = false

	var animation_name: String = "idle"

	if dash.is_dashing:
		animation_name = "dash"
	elif slam.is_slamming:
		animation_name = "slam"
	elif grapple.is_grappling:
		animation_name = "grapple"
	elif wall.is_wall_sliding:
		animation_name = "wall_slide"
	elif not player.is_on_floor():
		animation_name = "jump" if player.velocity.y < 0.0 else "fall"
	elif absf(player.velocity.x) > run_animation_threshold:
		animation_name = "run"

	if not sprite.sprite_frames.has_animation(animation_name):
		if player.is_on_floor() and absf(player.velocity.x) <= run_animation_threshold:
			animation_name = "idle"
		else:
			animation_name = "run"

	if not sprite.sprite_frames.has_animation(animation_name):
		return

	if sprite.animation != animation_name or not sprite.is_playing():
		sprite.play(animation_name)

	if animation_name == "run":
		var horizontal_speed: float = absf(player.velocity.x)
		var speed_ratio: float = horizontal_speed / maxf(reference_run_speed, 1.0)

		sprite.speed_scale = clampf(
			speed_ratio,
			minimum_run_scale,
			maximum_run_scale
		)
	else:
		sprite.speed_scale = 1.0
