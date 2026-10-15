
extends CharacterBody2D

@onready var movement = $MovementComponent
@onready var dash = $DashComponent
@onready var animation_component = get_node_or_null("AnimationComponent")

func _physics_process(delta: float) -> void:
	var horizontal: float = Input.get_axis("move_left", "move_right")

	if horizontal != 0.0:
		dash.facing_direction = horizontal

	dash.update_dash(delta)

	var movement_locked: bool = dash.is_dashing or dash.dash_ended_this_frame

	movement.update_movement(delta, movement_locked)

	move_and_slide()

	if animation_component:
		animation_component.update_animation()
