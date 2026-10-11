
extends CharacterBody2D

@onready var movement = $MovementComponent

func _physics_process(delta: float) -> void:
	movement.update_movement(delta)
	move_and_slide()
