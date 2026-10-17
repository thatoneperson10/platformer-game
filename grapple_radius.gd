extends Node2D

@export_group("Appearance")
@export var radius: float = 240.0
@export var circle_color: Color = Color(0.2, 0.85, 1.0, 0.35)
@export var line_width: float = 1.5
@export var show_radius: bool = true

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	if not show_radius:
		return

	draw_arc(
		Vector2.ZERO,
		radius,
		0.0,
		TAU,
		96,
		circle_color,
		line_width,
		true
	)
