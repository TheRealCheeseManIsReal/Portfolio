extends ColorRect

var muted = false

const notes = [
	preload("res://Note0.wav"),
	preload("res://Note1.wav"),
	preload("res://Note2.wav"),
	preload("res://Note3.wav"),
	preload("res://Note4.wav"),
	preload("res://Note5.wav"),
	preload("res://Note6.wav"),
	preload("res://Note7.wav")
]

var bools = [true, true, true, true, false, false, true]
var text = ["imagx", "imagy", "focusx", "focusy", "pressure", "time", "rng"]

var slength : int

var Equation : Array = []

enum Operators {add, subtract, multiply, divide, power, root, modulo, logarithm}
enum Modifiers {abs, sin, cos, tan, neg, na, squart, square}
enum Variables {x, y, mousex, mousey, mdown, time, rng}
enum Directions {left, right}

var maximum : float
var minimum : float


var campos : Vector2 = Vector2(0.0, 0.0)
var zoom : float = 1.0

var speed : float = 1.0

var rng : float

var done : bool = false

var colour : bool = false

@onready var load_rect: ColorRect = $LoadRect
@onready var label: Label = $Label
@onready var timer: Timer = $Timer
@onready var music: AudioStreamPlayer = $MusicPlayer
@onready var note: AudioStreamPlayer = $NotePlayer
@onready var st: Timer = $sTimer
@onready var updates: Label = $updates

# Randomizes the seed, and creates a starting equation
func _ready() -> void:
	randomize()
	rng = randf_range(-100.0, 100.0)
	create_equation(randi_range(1, 100))
	findmaxmin()
	campos = Vector2(0.0, 0.0)
	zoom = 1.0
	Equation[400] = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Dream"):
		load_rect.visible = true
		label.visible = true
		timer.start()
		done = false
		rng = randf_range(-100.0, 100.0)
		create_equation(randi_range(1, 100))
		findmaxmin()
		campos = Vector2(0.0, 0.0)
		zoom = 1.0
		Equation[400] = 1
	 
	if Input.is_action_pressed("speed up"):
		speed = 4.0
	else:
		speed = 1.0
	
	campos.x += ((Input.get_axis("move left", "move right")) * 0.004) * zoom * speed
	campos.y += ((Input.get_axis("move up", "move down")) * 0.004) * zoom * speed
	zoom *= 1.0 + ((Input.get_axis("zoom in", "zoom out")) * 0.0085) * speed
	
	material.set_shader_parameter("Equation", Equation)
	material.set_shader_parameter("maximum", maximum)
	material.set_shader_parameter("maximum", minimum)
	var mousepos = get_local_mouse_position()
	mousepos /= Vector2(1152.0, 648.0)
	mousepos -= Vector2(0.5, 0.5)
	material.set_shader_parameter("mousepos", mousepos)
	material.set_shader_parameter("campos", campos)
	material.set_shader_parameter("zoom", zoom)
	material.set_shader_parameter("mdown", 1.0 if Input.is_action_pressed("down") else -1.0)
	material.set_shader_parameter("rng", rng)
	material.set_shader_parameter("colour", colour)
	
	if randi_range(1, 100000) == 1:
		if not music.playing:
			music.play()
	
	toggles()

# Creates a new equation
func create_equation(length = 100):
	Equation = []
	for x in 401:
		Equation.append(0)
	
	slength = length * 4
	
	for i in 100:
		if i < length:
			Equation[(i * 4)] = randi_range(0, 1) # direction
			Equation[(i * 4) + 1] = randi_range(0, 7) # operation
			Equation[(i * 4) + 2] = randi_range(0, 7) # modifier
			Equation[(i * 4) + 3] = randi_range(0, 6) # variable
			while not bools[Equation[(i * 4) + 3]]:
				Equation[(i * 4) + 3] = randi_range(0, 6)
		else:
			Equation[(i * 4)] = 9
			Equation[399] = 9
	

# Using actual numbers, finds the result of the current equation
func evaluate(x, y, mx, my, md, t, r):
	var vars : Array = [x, y, mx, my, md, t, r]
	var result : float = call_math(Equation[2], vars[Equation[3]])
	
	var i : int = 1
	var b : float
	while Equation[i * 4] != 9:
		
		if Equation[i * 4] == Directions.left:
			result = call_math(Equation[(i * 4) + 2], result)
			b = vars[Equation[(i * 4) + 3]]
			result = call_math(Equation[(i * 4) + 1], b, result)
		else:
			b = call_math(Equation[(i * 4) + 2], vars[Equation[(i * 4) + 3]])
			result = call_math(Equation[(i * 4) + 1], result, b)
		
		i += 1
		if i == 100:
			break
	
	return result

# Runs a maths function, runs a modifier if b is undefined
func call_math(f, a, b = NAN):
	if is_nan(b):
		match f:
			0:
				return Maths.absolute(a)
			1:
				return Maths.sine(a)
			2:
				return Maths.cosine(a)
			3:
				return Maths.tangent(a)
			4:
				return a * -1.0
			5:
				return a
			6:
				return Maths.squart(a)
			7:
				return Maths.square(a)
	else:
		match f:
			0:
				return Maths.add(a, b)
			1:
				return Maths.subtract(a, b)
			2:
				return Maths.multiply(a, b)
			3:
				return Maths.divide(a, b)
			4:
				return Maths.power(a, b)
			5:
				return Maths.root(a, b)
			6:
				return Maths.modulo(a, b)
			7:
				return Maths.logarithm(a, b)

# Finds the highest and lowest values that evaluating the equation produces
func findmaxmin():
	var results : Array = []
	var variab : Array = []
	
	for i in 5000:
		var x = randf_range(-0.5, 0.5)
		var y = randf_range(-0.5, 0.5)
		var mx = randf_range(-0.5, 0.5)
		var my = randf_range(-0.5, 0.5)
		var md = -1.0 if randf() < 0.5 else 1.0
		var t = randf_range(0.0, 6000.0)
		var r = rng
		
		variab.append([x, y, mx, my, md, t, r])
		results.append(evaluate(x, y, mx, my, md, t, r))
	
	maximum = results.max()
	minimum = results.min()
	
	if maximum == INF:
		while results.has(INF):
			results.remove_at(results.find(INF))
		if results.size() > 0:
			maximum = results.max()
		else:
			maximum = 0.0
	
	if minimum == -INF:
		while results.has(-INF):
			results.remove_at(results.find(-INF))
		if results.size() > 0:
			minimum = results.min()
		else:
			minimum = 0.0
	
	done = true
	playSong()

func _on_timer_timeout() -> void:
	if done:
		load_rect.visible = false
		label.visible = false
	else:
		timer.start()

var running = false
var cancel = false

# Plays a song
func playSong():
	if running:
		cancel = true
	running = true
	cancel = false
	for i in slength:
		note.stream = notes[Equation[i]]
		note.play()
		st.start(0.025)
		await st.timeout
		if cancel:
			break
	running = false

# Handels toggles
func toggles():
	for i in 7:
		if Input.is_action_just_pressed("toggle" + str(i + 1)):
			note.stream = notes[i]
			note.play()
			bools[i] = not bools[i]
			if bools[i]:
				update(text[i] + "_enabled")
			else:
				update(text[i] + "_disabled")
	if Input.is_action_just_pressed("mute"):
		muted = not muted
		if muted:
			update("sound_disabled")
			AudioServer.set_bus_mute(0, true)
		else:
			update("sound_enabled")
			AudioServer.set_bus_mute(0, false)
	if Input.is_action_just_pressed("color"):
		colour = not colour

func update(tex : String):
	updates.text = tex
	updates.visible = true
	st.start(1.0)
	await st.timeout
	for i in 51:
		updates.modulate.a -= 5
		st.start(0.02)
		await st.timeout
	updates.visible = false
	updates.modulate.a = 255
