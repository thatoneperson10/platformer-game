
extends Node

@export_group("Afterimages")
@export var enabled: bool = true
@export var spawn_interval: float = 0.025
@export var fade_duration: float = 0.25
@export var afterimage_color: Color = Color(0.25, 0.85, 1.0, 0.8)
@export var ghost_z_index: int = 5

@onready var player: CharacterBody2D = get_parent()
@onready var sprite: AnimatedSprite2D = player.get_node("AnimatedSprite2D")

var spawn_timer: float = 0.0
var was_dashing: bool = false
var active_ghosts: Array[Sprite2D] = []

func update_afterimages(delta: float, dash_active: bool) -> void:
	if not enabled or not dash_active:
		was_dashing = false
		spawn_timer = 0.0
		return

	var interval: float = maxf(spawn_interval, 0.001)

	if not was_dashing:
		was_dashing = true
		spawn_timer = 0.0

	spawn_timer -= delta

	while spawn_timer <= 0.0:
		spawn_afterimage()
		spawn_timer += interval

func spawn_afterimage() -> void:
	if sprite.sprite_frames == null:
		return

	if not sprite.sprite_frames.has_animation(sprite.animation):
		return

	var texture: Texture2D = sprite.sprite_frames.get_frame_texture(
		sprite.animation,
		sprite.frame
	)

	if texture == null:
		return

	var world: Node = get_tree().current_scene

	if world == null:
		return

	var ghost: Sprite2D = Sprite2D.new()

	ghost.texture = texture
	ghost.centered = sprite.centered
	ghost.offset = sprite.offset
	ghost.flip_h = sprite.flip_h
	ghost.flip_v = sprite.flip_v
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.modulate = afterimage_color
	ghost.z_index = ghost_z_index

	world.add_child(ghost)
	ghost.global_transform = sprite.global_transform

	active_ghosts.append(ghost)

	ghost.tree_exiting.connect(
		func() -> void:
			active_ghosts.erase(ghost)
	)

	var tween: Tween = ghost.create_tween()

	tween.tween_property(
		ghost,
		"modulate:a",
		0.0,
		maxf(fade_duration, 0.01)
	)

	tween.tween_callback(ghost.queue_free)

func reset_afterimages() -> void:
	was_dashing = false
	spawn_timer = 0.0

	for ghost in active_ghosts.duplicate():
		if is_instance_valid(ghost):
			ghost.queue_free()

	active_ghosts.clear()
