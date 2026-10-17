extends Node

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
	elif absf(player.velocity.x) > 10.0:
		animation_name = "run"

	if not sprite.sprite_frames.has_animation(animation_name):
		animation_name = "run" if absf(player.velocity.x) > 10.0 else "idle"

	if sprite.sprite_frames.has_animation(animation_name):
		if sprite.animation != animation_name or not sprite.is_playing():
			sprite.play(animation_name)
