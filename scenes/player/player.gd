
extends CharacterBody2D

@onready var movement = $MovementComponent
@onready var dash = $DashComponent
@onready var wall = $WallMovementComponent
@onready var slam = $SlamComponent
@onready var grapple = $GrappleComponent
@onready var afterimage = $AfterimageComponent
@onready var animation_component = get_node_or_null("AnimationComponent")

var spawn_position: Vector2

func _ready() -> void:
	spawn_position = global_position

func _physics_process(delta: float) -> void:
	var horizontal: float = Input.get_axis("move_left", "move_right")

	if horizontal != 0.0:
		dash.facing_direction = horizontal

	dash.update_dash(delta)

	var dash_visual_active: bool = dash.is_dashing or dash.dash_ended_this_frame

	grapple.update_input()

	if grapple.is_grappling:
		if dash.is_dashing:
			dash.cancel_dash()

		if slam.is_slamming:
			slam.cancel_slam()

	var dash_locked: bool = dash.is_dashing or dash.dash_ended_this_frame

	if Input.is_action_just_pressed("slam"):
		grapple.detach()

	slam.update_slam(delta, dash_locked)

	var movement_locked: bool = dash_locked or slam.is_slamming

	movement.update_movement(
		delta,
		movement_locked,
		wall.is_horizontal_locked() or (
			grapple.is_grappling and not is_on_floor()
		)
	)

	wall.update_wall_movement(
		delta,
		movement_locked,
		movement
	)

	grapple.apply_grapple(delta)

	move_and_slide()

	grapple.after_move()
	slam.after_move()

	if animation_component:
		animation_component.update_animation()

	afterimage.update_afterimages(delta, dash_visual_active)

func respawn() -> void:
	grapple.reset_grapple()

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
	wall.wall_jump_direction = 0.0

	movement.coyote_timer = 0.0
	movement.jump_buffer_timer = 0.0

	afterimage.reset_afterimages()

	reset_physics_interpolation()
