
extends CharacterBody2D

@onready var movement = $MovementComponent
@onready var dash = $DashComponent
@onready var wall = $WallMovementComponent
@onready var slam = $SlamComponent
@onready var animation_component = get_node_or_null("AnimationComponent")

var spawn_position: Vector2

func _physics_process(delta: float) -> void:
	var horizontal: float = Input.get_axis("move_left", "move_right")

	if horizontal != 0.0:
		dash.facing_direction = horizontal

	if not slam.is_slamming:
		dash.update_dash(delta)

	var dash_locked: bool = dash.is_dashing or dash.dash_ended_this_frame

	slam.update_slam(delta, dash_locked)

	var movement_locked: bool = dash_locked or slam.is_slamming

	movement.update_movement(
		delta,
		movement_locked,
		wall.is_horizontal_locked()
	)

	wall.update_wall_movement(
		delta,
		movement_locked,
		movement
	)

	move_and_slide()

	slam.after_move()

	if animation_component:
		animation_component.update_animation()

func _ready() -> void:
	spawn_position = global_position

func respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO

	dash.is_dashing = false
	dash.can_dash = true
	dash.dash_timer = 0.0
	dash.dash_ended_this_frame = false
	dash.dash_velocity = Vector2.ZERO

	slam.is_slamming = false
	slam.is_starting = false
	slam.can_slam = true
	slam.startup_timer = 0.0

	wall.is_wall_sliding = false
	wall.wall_jump_lock_timer = 0.0

	movement.coyote_timer = 0.0
	movement.jump_buffer_timer = 0.0

	reset_physics_interpolation()
