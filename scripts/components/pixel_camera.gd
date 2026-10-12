extends Camera2D

@export var target: Node2D
@export var follow_speed: float = 8.0
@export var pixel_size: float = 1.0

var smooth_position: Vector2


func _ready() -> void:
	position_smoothing_enabled = false
	process_callback = Camera2D.CAMERA2D_PROCESS_IDLE

	if target:
		smooth_position = target.global_position
		global_position = smooth_position


func _process(delta: float) -> void:
	if not target:
		return

	var weight = 1.0 - exp(-follow_speed * delta)

	smooth_position = smooth_position.lerp(
		target.global_position,
		weight
	)

	global_position = Vector2(
		roundf(smooth_position.x / pixel_size) * pixel_size,
		roundf(smooth_position.y / pixel_size) * pixel_size
	)
