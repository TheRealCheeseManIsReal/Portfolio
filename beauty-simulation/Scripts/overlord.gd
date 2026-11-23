extends TileMapLayer

var O = SuperOverlord

var start = false
var tick_speed = 10

const WALL_NOISE : Texture2D = preload("uid://y6lh61dvdfsb")
@onready var walls: TileMapLayer = $Walls
@onready var foods: TileMapLayer = $Foods
@onready var checker: TileMapLayer = $Checker
@onready var ts: Control = $CanvasLayer/TS

@onready var fg: Line2D = $"CanvasLayer/Food Graph"
@onready var pg: Line2D = $"CanvasLayer/Population Graph"
@onready var reader: Line2D = $"CanvasLayer/Graph Reader"

func render():
	clear()
	
	for i in O.Organisms.size():
		var Org : Organism = O.Organisms[i]
		var MakeData
		
		if Org.rotation != 0:
			MakeData = Org.rotate(Org.rotation)
		else:
			MakeData = [Org.Form, Org.volume]
		
		for n in MakeData[1].size():
			
			if O.ROTATES.has(MakeData[0][MakeData[1][n]][0]) && MakeData[0][MakeData[1][n]][1] != 0:
				set_cell(Org.Location + MakeData[1][n], 1, MakeData[0][MakeData[1][n]][0], MakeData[0][MakeData[1][n]][1])
			else:
				set_cell(Org.Location + MakeData[1][n], 1, MakeData[0][MakeData[1][n]][0])

func addabunchofgrubs(amount, radius = 250):
	for i in amount:
		var grub1 : Organism = Organism.new()
		grub1.presetGrub()
		grub1.volm()
		for n in randi_range(0, 2):
			grub1.mutate()
		grub1.Location = Vector2i(randi_range(radius * -1, radius), randi_range(radius * -1, radius))
		grub1.rotation = randi_range(0, 3)
		while grub1.test_valid_location(grub1.Location, grub1.rotation) == false:
			grub1.Location = Vector2i(randi_range(radius * -1, radius), randi_range(radius * -1, radius))
		grub1.setup()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	O.approx_e()
	
	await WALL_NOISE.changed
	var WI = WALL_NOISE.get_image()
	
	var popgraph = Graph.new()
	popgraph.baseValue = 1000.0
	popgraph.data = [1000.0]
	popgraph.cLine = pg
	
	O.GRAPHS = [popgraph]
	
	for x in 1000:
		O.World.append([])
		for y in 1000:
			@warning_ignore("unused_variable")
			var colo : Color = WI.get_pixel(x, y) 
			# colo.a < 0.75 &&
			var tile = O.TILE["empty"] if x % 999 != 0 && y % 999 != 0 else O.TILE["wall"]
			
			if (x + (y % 2)) % 2 == 0:
				checker.set_cell(Vector2i(x - 500, y - 500), 1, O.TILE["checker"])
			else:
				checker.set_cell(Vector2i(x - 500, y - 500), 1, O.TILE["empty"])
			
			O.World[x].append(tile)
			walls.set_cell(Vector2i(x - 500, y - 500), 1, O.World[x][y])
	
	for i in 30000:
		placeFood()
	
	addabunchofgrubs(1000, 475)
	
	start = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if start:
		TICK()
	
	if Input.is_action_just_pressed("Toggle Graphs"):
		if O.GRAPHS[0].cLine.visible:
			for i in O.GRAPHS.size():
				O.GRAPHS[i].cLine.visible = false
			reader.visible = false
		else:
			for i in O.GRAPHS.size():
				O.GRAPHS[i].cLine.visible = true
			reader.visible = true
	
	if Input.is_action_just_pressed("Value Check"):
		var f = 0
		var o = 0
		var org = 0
		
		for x in 1000:
			for y in 1000:
				if O.ORGANICS.has(O.World[x][y]):
					if !O.ORGANICS.has(get_cell_atlas_coords(Vector2i(x - 500, y - 500))):
						walls.set_cell(Vector2i(x - 500, y - 500), 1, O.TILE["wall"], 1)
					o += 1
				elif O.World[x][y] != O.TILE["wall"]:
					walls.set_cell(Vector2i(x - 500, y - 500), 1, O.TILE["empty"])
				
				if O.World[x][y] == O.TILE["food"]:
					f += 1
				
				if O.World[x][y] == O.TILE["core"]:
					org += 1
		
		print("TICK " + str(O.fake_ticks))
		print("Organisms: " + str(org))
		print("Food: " + str(f))
		print("Organics: " + str(o))
		print("Density: " + str((f + o) / 100000.0))
		print("")

func TICK():
	updateData()
	O.Ticks += 1
	
	if ts && ts.lineg.is_editing() == false:
		tick_speed = int(ts.lineg.text)
	
	if tick_speed != 0 && O.Ticks % tick_speed == 0:
		for i in O.Organisms.size():
			if i < O.Organisms.size():
				O.Organisms[i].Tick()
		
		updateFood()
		render()
		
		while (O.foods + O.organs) / 100000.0 < 0.24: 
			placeFood()
		
		O.fake_ticks += 1
		
		O.GRAPHS[0].data.append(O.Organisms.size())
		graphing()

func graphing():
	if O.fake_ticks == int(10000 * pow(2, O.modules - 1)):
		O.modules += 1
	
	for g in O.GRAPHS.size():
		var graph : Graph = O.GRAPHS[g]
		graph.cLine.clear_points()
		graph.cLine.default_color = graph.color
		
		@warning_ignore("integer_division")
		var mult = graph.data.size() / O.modules
		
		for i in mult:
			var value = graph.data[i * O.modules]
			graph.cLine.add_point( Vector2(i * (1152.0 / (mult - 1)), 648.0 - (value / (graph.baseValue / 324.0)) ) )

# Places a single tile of food in a random free position, or a specified position
func placeFood(cell = 0):
	var quads
	if typeof(cell) == TYPE_INT:
		quads = Vector2i(randi_range(0, 999), randi_range(0, 999))
	else:
		quads = cell + Vector2i(500, 500)
	if O.VOIDS.has(O.World[quads.x][quads.y]):
		O.World[quads.x][quads.y] = O.TILE["food"]
		foods.set_cell(quads - Vector2i(500, 500), 1, O.TILE["food"])
		O.foods += 1

func updateFood():
	for i in O.updates.size():
		foods.set_cell(O.updates[i], 1, O.TILE["empty"])
		O.foods -= 1
	O.updates = []

# Updates the data shown in the UI
func updateData():
	var label : RichTextLabel = ts.data
	
	label.text = ""
	label.append_text("TICK " + str(O.fake_ticks) + "\n")
	label.append_text("Organisms: " + str(O.Organisms.size()) + "\n")
	label.append_text("Food: " + str(O.foods) + "\n")
	label.append_text("Food eaten: " + str(O.foods_eaten) + "\n")
	label.append_text("Organics: " + str(O.organs) + "\n")
	label.append_text("Organics eaten: " + str(O.organics_eaten) + "\n")
	label.append_text("Density: " + str((O.foods + O.organs) / 100000.0) + "\n")
	
