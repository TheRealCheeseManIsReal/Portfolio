extends Line2D

var O = SuperOverlord

@onready var text: RichTextLabel = $RichTextLabel

var mouse_x
var graph : Line2D
var point

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	mouse_x = get_global_mouse_position().x
	position.x = mouse_x
	
	if O.GRAPHS.size() > 0:
		graph = O.GRAPHS[0].cLine
		point = int((mouse_x * graph.points.size()) / 1152.0 )
		
		if point < graph.points.size():
			set_point_position(1, Vector2(0.0, graph.points[point].y))
			
			text.clear()
			text.append_text("Tick " + str(point * O.modules) + "\n")
			text.append_text(str(O.GRAPHS[0].data[(point - 1) * O.modules]) + " Organisms" + "\n")
