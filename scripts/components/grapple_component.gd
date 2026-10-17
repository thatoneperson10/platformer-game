
extends Node

@export_group("Grapple")
@export var grapple_range: float = 240.0
@export var minimum_rope_length: float = 24.0
@export var maximum_rope_length: float = 320.0

@export_group("Grapple Catch")
@export_range(0.0, 1.0, 0.05) var catch_assist: float = 0.85
@export var catch_speed_multiplier: float = 1.0

@export_group("Rope Visuals")
@export var rope_sag_strength: float = 0.7
@export var rope_segments: int = 24
@export var rope_smoothing: float = 12.0

@onready var player: CharacterBody2D = get_parent()
@onready var rope: Line2D = player.get_node("GrappleLine")

var is_grappling: bool = false
var anchor: Node2D = null
var rope_length: float = 0.0
var current_sag: float = 0.0

func _ready() -> void:
	rope.visible = false
	rope.clear_points()

func update_input() -> void:
	if Input.is_action_just_released("grapple"):
		detach()

	if Input.is_action_just_pressed("grapple"):
		try_grapple()

func try_grapple() -> void:
	if is_grappling:
		return

	var closest: Node2D = null
	var closest_distance: float = grapple_range

	for candidate in get_tree().get_nodes_in_group("grapple_anchor"):
		if not candidate is Node2D:
			continue

		var point: Node2D = candidate
		var distance: float = player.global_position.distance_to(point.global_position)

		if distance > closest_distance:
			continue

		closest = point
		closest_distance = distance

	if closest == null:
		return

	anchor = closest
	rope_length = clampf(
		closest_distance,
		minimum_rope_length,
		maximum_rope_length
	)

	is_grappling = true
	apply_catch_assist()

	rope.visible = true
	update_rope()

func apply_catch_assist() -> void:
	var offset: Vector2 = player.global_position - anchor.global_position

	if offset.length_squared() < 0.001:
		return

	var radial: Vector2 = offset.normalized()
	var tangent: Vector2 = Vector2(-radial.y, radial.x)

	var incoming_speed: float = player.velocity.length()
	var tangential_speed: float = player.velocity.dot(tangent)

	if incoming_speed < 0.01:
		return

	if absf(tangential_speed) < 0.01:
		return

	var target_speed: float = signf(tangential_speed) * incoming_speed
	target_speed *= catch_speed_multiplier

	var assisted_speed: float = lerpf(
		tangential_speed,
		target_speed,
		catch_assist
	)

	var inward_speed: float = minf(player.velocity.dot(radial), 0.0)

	player.velocity = tangent * assisted_speed
	player.velocity += radial * inward_speed

func apply_grapple(delta: float) -> void:
	if not is_grappling:
		return

	if not is_instance_valid(anchor):
		detach()
		return

	var offset: Vector2 = player.global_position - anchor.global_position
	var distance: float = offset.length()

	if distance < 0.001:
		return

	var radial: Vector2 = offset / distance

	if distance >= rope_length:
		var outward_speed: float = player.velocity.dot(radial)

		if outward_speed > 0.0:
			player.velocity -= radial * outward_speed

		var excess: float = distance - rope_length

		if excess > 0.0 and delta > 0.0:
			player.velocity -= radial * (excess / delta)

func after_move() -> void:
	if not is_grappling:
		return

	if not is_instance_valid(anchor):
		detach()
		return

	var offset: Vector2 = player.global_position - anchor.global_position
	var distance: float = offset.length()

	if distance > rope_length and distance > 0.001:
		var correction: Vector2 = -offset.normalized() * (
			distance - rope_length
		)

		player.move_and_collide(correction)

	update_rope(get_physics_process_delta_time())


func update_rope(delta: float = 0.016) -> void:
	if not is_grappling or not is_instance_valid(anchor):
		return

	var start: Vector2 = player.global_position
	var end: Vector2 = anchor.global_position

	var distance: float = start.distance_to(end)
	var slack: float = maxf(rope_length - distance, 0.0)

	var target_sag: float = slack * rope_sag_strength

	current_sag = lerpf(
		current_sag,
		target_sag,
		1.0 - exp(-rope_smoothing * delta)
	)

	var points: PackedVector2Array = PackedVector2Array()

	for i in range(rope_segments + 1):
		var t: float = float(i) / float(rope_segments)

		var point: Vector2 = start.lerp(end, t)

		var sag: float = sin(t * PI) * current_sag

		point.y += sag

		points.append(rope.to_local(point))

	rope.points = points


func detach() -> void:
	is_grappling = false
	anchor = null
	rope_length = 0.0
	current_sag = 0.0
	
	rope.visible = false
	rope.clear_points()

func reset_grapple() -> void:
	detach()
