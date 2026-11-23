extends CharacterBody2D

@onready var camera: Camera2D = $Camera2D
const MAX_SPEED = 600.0
const ZOOM_SPEED = 0.04


func _physics_process(_delta: float) -> void:
	var lrdirection := Input.get_axis("ui_left", "ui_right")
	var uddirection := Input.get_axis("ui_up", "ui_down")
	var zoom := Input.get_axis("Zoom Out", "Zoom In")
	
	if lrdirection:
		velocity.x = MAX_SPEED * lrdirection / camera.zoom.x
	else:
		velocity.x *= 0.9
	
	if uddirection:
		velocity.y = MAX_SPEED * uddirection / camera.zoom.x
	else:
		velocity.y *= 0.9
	
	var zvelo = 0.0
	if zoom:
		zvelo = ZOOM_SPEED * zoom * camera.zoom.x
	else:
		zvelo *= 0.9
	
	move_and_slide()
	camera.zoom.x += zvelo
	camera.zoom.y = camera.zoom.x
