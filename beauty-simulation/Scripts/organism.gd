class_name Organism
extends Resource

enum NTYPE {L, A}

var O = SuperOverlord

var Parent : Organism
var children = []

var Location : Vector2i = Vector2i(0, 0)
var Energy : int
var rotation = 0
var Acceptance : float
var acepnum : int
var foods : float = 1.0
var actions : float = 0.0
var stomach : int = 0

var alive = true

var BF = {}
var Form = {
	Vector2i(0, 0) : O.TILE["core"]
}
var volume = []

var Stimuli = {
	"front" : false,
	"hurt" : false,
	"success" : false,
}
var Mind = {}

# Defines volumes based on Form
func volm():
	volume = Form.keys()

# Sets stimuli, life, and actions variables according to Form
func setup():
	volm()
	var keys = Form.keys()
	for i in keys.size():
		BF[keys[i]] = Form[keys[i]]
	@warning_ignore("narrowing_conversion")
	Energy = 400 + (25 * pow(volume.size(), 2))
	Acceptance = acepeq(acepnum)
	stamp_self()
	O.organs += volume.size()
	
	O.Organisms.append(self)

# Sets Form to default Grub
func presetGrub():
	acepnum = -45
	
	Form = {
		Vector2i(0, 0) : [O.TILE["core"], 0],
		Vector2i(-1, 0) : [O.TILE["pivoter"], 0],
		Vector2i(1, 0) : [O.TILE["stepper"], 0],
		Vector2i(2, 0) : [O.TILE["chomper"], 1]
	}
	
	newNero("front", NTYPE.L)
	newNero("hurt", NTYPE.L)
	newNero("success", NTYPE.L)
	newNero(Vector2i(-1, 0), NTYPE.A, 1)
	newNero(Vector2i(-1, 0), NTYPE.A, 2)
	newNero(Vector2i(-1, 0), NTYPE.A, 3)
	newNero(Vector2i(1, 0), NTYPE.A)
	newNero(Vector2i(2, 0), NTYPE.A)
	newNero(Vector2i(0, 0), NTYPE.A)
	
	newNero(Vector2i(-1, 0), NTYPE.L)
	newNero(Vector2i(1, 0), NTYPE.L)
	newNero(Vector2i(2, 0), NTYPE.L)
	newNero(Vector2i(0, 0), NTYPE.L)

func Tick():
	randomize()
	update_self()
	if (stomach == volume.size() - 1 && volume.size() != 0 && volume.has(Vector2i(0, 0)) && Form[Vector2i(0, 0)][0] == O.TILE["core"] && volume.size() != 1) || (volume.size() == 1 && stomach == 1 && volume.has(Vector2i(0, 0)) && Form[Vector2i(0, 0)][0] == O.TILE["core"] ):
		mitosis()
		stomach = 0
	clear_location()
	if (foods / actions) < Acceptance:
		rethink()
	ponder()
	if alive:
		stamp_self()

# Add/Remove/Switch random tile in Form
func mutate():
	var options = Form.keys()
	var Cell : Vector2i = options[randi_range(0, options.size() - 1)]
	
	if randf() < 0.33: # switch
		meninblack(Cell)
		
		Form[Cell] = [O.randMute(), randi_range(0, 3)]
		var NewCell = Form[Cell][0]
		
		if O.ACTIONS.has(NewCell):
			if NewCell == O.TILE["pivoter"]:
				newNero(Cell, NTYPE.A, 1)
				newNero(Cell, NTYPE.A, 2)
				newNero(Cell, NTYPE.A, 3)
			else:
				newNero(Cell, NTYPE.A)
			newNero(Cell, NTYPE.L)
		elif O.SENSORS.has(NewCell):
			newNero(Cell, NTYPE.L)
			
	elif randf() < 0.5 && volume.size() > 1: # remove
		meninblack(Cell)
		Form.erase(Cell)
		volm()
		
	else: # add
		var Add = Vector2i(randi_range(-1, 1), randi_range(-1, 1))
		if Add.x != 0 && Add.y != 0:
			if randf() < 0.5:
				Add.x = 0
			else:
				Add.y = 0
		Cell += Add
		while Form.has(Cell):
			Cell = options[randi_range(0, options.size() - 1)]
			Cell += Vector2i(randi_range(-1, 1), randi_range(-1, 1))
			if Cell.x != 0 && Cell.y != 0:
				if randf() < 0.5:
					Cell.x = 0
				else:
					Cell.y = 0
		
		Form[Cell] = [O.randMute(), randi_range(0, 3)]
		var cellu = Form[Cell][0]
		
		if O.ACTIONS.has(cellu):
			if cellu == O.TILE["pivoter"]:
				newNero(Cell, NTYPE.A, 1)
				newNero(Cell, NTYPE.A, 2)
				newNero(Cell, NTYPE.A, 3)
			else:
				newNero(Cell, NTYPE.A)
			newNero(Cell, NTYPE.L)
		elif O.SENSORS.has(cellu):
			newNero(Cell, NTYPE.L)
		volm()

func meninblack(Cell : Vector2i):
	if Stimuli.has(Cell):
		Stimuli.erase(Cell)
	var check = true
	while check:
		check = false
		var keys = Mind.keys()
		for i in keys.size():
			var Nero : Neuron = Mind[keys[i]]
			if  typeof(Nero.Connection) != TYPE_STRING && Nero.Connection == Cell:
				Mind.erase(keys[i])
				check = true
				break

# Carry out action, if possible
func preform(cell : Vector2i, variation):
	var check = Stimuli.keys()
	for i in check.size():
		if typeof(check[i]) == TYPE_VECTOR2I:
			Stimuli[check[i]] = false
	
	Stimuli[cell] = true
	
	Energy -= 4
	if Form.has(cell) && volume.has(cell):
		if Form[cell][0] == O.TILE["stepper"]:
			step(cell)
		if Form[cell][0] == O.TILE["pivoter"]:
			pivot(cell, variation)
		if Form[cell][0] == O.TILE["chomper"]:
			chomp(cell)
		if Form[cell][0] == O.TILE["core"]:
			# Action of doing nothing
			Stimuli["success"] = true
		else:
			actions += 1.0
	if Energy < 1:
		death()

# Duplicate self and set to appropriate location, has a chance to mutate
func mitosis():
	var Child : Organism = Organism.new()
	Child.Parent = self
	
	var keys = BF.keys()
	for i in keys.size():
		Child.Form[keys[i]] = BF[keys[i]]
	
	Child.Acceptance = Acceptance
	
	var mk = Mind.keys()
	Child.Mind = {}
	for i in mk.size():
		var Nero : Neuron = Mind[mk[i]]
		Child.Mind[mk[i]] = dupe_neuron(Nero)
	
	keys = Stimuli.keys()
	for i in keys.size():
		Child.Stimuli[keys[i]] = Stimuli[keys[i]]
	
	if randf() < 0.25:
		Child.mutate()
	
	Child.volm()
	
	var testdist = 2
	var updown
	var leftright
	
	if randf() < 0.3:
		Child.acepnum = acepnum + randi_range(-1, 1)
	else:
		Child.acepnum = acepnum
	
	while true:
		updown = -1 if randf() > 0.5 else 1
		leftright = -1 if randf() > 0.5 else 1
		Child.Location = Location + Vector2i(leftright * testdist, updown * testdist)
		Child.rotation = randi_range(0, 3)
		
		if Child.test_valid_location(Child.Location, Child.rotation):
			Child.setup()
			if randf() < 0.25:
				Child.rethink()
			break
		
		if randf() < 0.2:
			testdist += 1
	
	children.append(Child)

#region Thinking

# Sets stimuli to true or false based on current conditions
func set_stimuli():
	var frontCell = get_frontest_cell()
	if O.VOIDS.has(O.World[frontCell.x + Location.x + 500][frontCell.y + Location.y + 500]):
		Stimuli["front"] = false
	else:
		Stimuli["front"] = true
	
	var stims = Stimuli.keys()
	
	for i in stims.size():
		if typeof(stims[i]) != TYPE_STRING && volume.has(stims[i]):
			if Form[stims[i]][0] == O.TILE["feeler"]:
				var cell : Vector2i = get_relative_cell(get_pointer_cell(stims[i], 1))
				cell += Vector2i(500, 500)
				Stimuli[stims[i]] = not O.VOIDS.has(O.World[cell.x][cell.y])
			elif Form[stims[i]][0] == O.TILE["sniffer"]:
				var cell : Vector2i = get_relative_cell(get_pointer_cell(stims[i], 2))
				cell += Vector2i(500, 500)
				Stimuli[stims[i]] = O.in_bounds(cell) && O.World[cell.x][cell.y] == O.TILE["food"]
			elif Form[stims[i]][0] == O.TILE["peeker"]:
				var cells = get_peeker_cells(stims[i])
				
				if volume.has(stims[i]):
					Stimuli[stims[i]] = false
				for n in cells.size():
					if O.World[cells[n].x + 500][cells[n].y + 500] == O.TILE["food"] || O.ORGANICS.has(O.World[cells[n].x + 500][cells[n].y + 500]):
						Stimuli[stims[i]] = true
		elif typeof(stims[i]) != TYPE_STRING:
			Stimuli[stims[i]] = "INVALID"
			pass

func get_peeker_cells(cell : Vector2i):
	var Rcells = []
	
	for z in 10:
		for n in ((z * 2) + 1):
			@warning_ignore("integer_division")
			Rcells.append(get_relative_cell(Vector2i(cell.x + z + 1, (cell.y - z) + n)))
	
	return Rcells

# Constructs a new Neuron object and adds it to Mind
func newNero(con, typ, vari = 0):
	var nero : Neuron = Neuron.new()
	nero.Type = typ
	nero.Connection = con
	nero.varition = vari
	Mind[randi()] = nero
	
	if typ == NTYPE.L:
		Stimuli[con] = false

# Modify random nueral path
func rethink():
	while true:
		var Nero : Neuron = Mind[Mind.keys()[randi_range(0, Mind.keys().size() - 1)]]
		if Nero.Type == NTYPE.L:
			var paths = Nero.Directors.keys()
			if paths.size() > 0:
				var path = PackedInt32Array(paths[randi_range(0, paths.size() - 1)])
				var rn = Mind.keys()[randi_range(0, Mind.keys().size() - 1)]
				while path.has(rn):
					rn = Mind.keys()[randi_range(0, Mind.keys().size() - 1)]
				Nero.Directors[path][randi_range(0, 1)] = rn
				break
	foods = 1.0
	actions = 0.0

# Use neural paths to decide action
func ponder():
	var path = PackedInt32Array([])
	var n = Mind.keys()[0]
	var Nero : Neuron
	
	set_stimuli()
	
	while true:
		Nero = Mind[n]
		if Nero.Type == NTYPE.L:
			path = PackedInt32Array(path)
			path.append(n)
			if Nero.Directors.has(path) == false:
				Nero.Directors[path] = []
				for i in 2:
					var rn = Mind.keys()[randi_range(1, Mind.keys().size() - 1)]
					while path.has(rn):
						rn = Mind.keys()[randi_range(1, Mind.keys().size() - 1)]
					Nero.Directors[path].append(rn)
			n = Nero.Directors[path][int(Stimuli[Nero.Connection])]
			if not Mind.keys().has(n):
				var rn = Mind.keys()[randi_range(1, Mind.keys().size() - 1)]
				while path.has(rn):
					rn = Mind.keys()[randi_range(1, Mind.keys().size() - 1)]
				Nero.Directors[path][int(Stimuli[Nero.Connection])] = rn
				n = rn
		else:
			preform(Nero.Connection, Nero.varition)
			break

# Sure-fire Neuron duplication that doesn't mess up data
func dupe_neuron(Nero : Neuron):
	var New : Neuron = Neuron.new()
	New.Connection = Nero.Connection
	New.Type = Nero.Type
	New.varition = Nero.varition
	New.Directors = Nero.Directors.duplicate(true)
	
	return New

#endregion

#region Transformations

# Using transformation functions, creates list of Form and volume after a rotation of specified degree
func rotate(degree, gForm = 0, gV = 0):
	if typeof(gForm) != TYPE_DICTIONARY:
		gForm = Form
		gV = volume
	var data
	
	match degree:
		1:
			data = transpose(gForm, gV)
			data = flipH(data[0], data[1])
		2:
			data = flipH(gForm, gV)
			data = flipV(data[0], data[1])
		3:
			data = transpose(gForm, gV)
			data = flipV(data[0], data[1])
	
	return data

# Returns list containing Form and volume variations with x and y values switched
func transpose(gForm = 0, gV = 0):
	if typeof(gForm) != TYPE_DICTIONARY:
		gForm = Form
		gV = volume
	
	var frm = {}
	var vlm = []
	
	for i in gV.size():
		vlm.append(Vector2i(gV[i].y, gV[i].x))
		frm[Vector2i(gV[i].y, gV[i].x)] = [gForm[gV[i]][0], 3 - gForm[gV[i]][1]]
	
	return [frm, vlm]

# Returns list containing Form and volume variations with x values flipped
func flipH(gForm = 0, gV = 0):
	if typeof(gForm) != TYPE_DICTIONARY:
		gForm = Form
		gV = volume
	
	var frm = {}
	var vlm = []
	
	for i in gV.size():
		vlm.append(Vector2i(gV[i].x * -1, gV[i].y))
		frm[Vector2i(gV[i].x * -1, gV[i].y)] = [gForm[gV[i]][0], (4 - gForm[gV[i]][1]) if gForm[gV[i]][1] % 2 != 0 else gForm[gV[i]][1]]
	
	return [frm, vlm]

# Returns list containing Form and volume variations with y values flipped
func flipV(gForm = 0, gV = 0):
	if typeof(gForm) != TYPE_DICTIONARY:
		gForm = Form
		gV = volume
	
	var frm = {}
	var vlm = []
	
	for i in gV.size():
		vlm.append(Vector2i(gV[i].x, gV[i].y * -1))
		frm[Vector2i(gV[i].x, gV[i].y * -1)] = [gForm[gV[i]][0], (2 - gForm[gV[i]][1]) if gForm[gV[i]][1] % 2 == 0 else gForm[gV[i]][1]]
	
	return [frm, vlm]

#endregion

#region Actions

func step(cell : Vector2i):
	cell = get_relative_cell(cell)
	if test_valid_location(Location + cell, rotation):
		Location += cell
		Stimuli["success"] = true
	else:
		Stimuli["success"] = false
		actions += 5.0

func pivot(cell : Vector2i, degree):
	var rotcell = get_relative_cell(cell)
	rotation += degree
	while rotation > 3:
			rotation -= 4
	var new = get_relative_cell(cell)
	if test_valid_location(Location + (rotcell - new), rotation):
		Location += rotcell - new
		Stimuli["success"] = true
	else:
		rotation -= degree
		while rotation < 0:
				rotation += 4
		Stimuli["success"] = false
		actions += 5.0

func chomp(cell : Vector2i):
	
	cell = Location + get_relative_cell(get_pointer_cell(cell, 1))
	if O.World[cell.x + 500][cell.y + 500] == O.TILE["food"] || O.ORGANICS.has(O.World[cell.x + 500][cell.y + 500]):
		
		if O.World[cell.x + 500][cell.y + 500] == O.TILE["food"]:
			O.foods_eaten += 1
			stomach += 1
			Energy += 25
			O.updates.append(cell)
		else:
			O.organics_eaten += 1
			O.organs -= 1
			Energy += 50
		
		O.World[cell.x + 500][cell.y + 500] = O.TILE["empty"]
		Stimuli["success"] = true
		foods += 1.0
	else:
		Stimuli["success"] = false
		actions += 5.0

#endregion

#region Location Data

# Returns cell a specified cell is pointing to
func get_pointer_cell(cell : Vector2i, distance):
	match Form[cell][1]:
		1:
			return Vector2i(cell.x + distance, cell.y)
		2:
			return Vector2i(cell.x, cell.y + distance)
		3:
			return Vector2i(cell.x - distance, cell.y)
		0:
			return Vector2i(cell.x, cell.y - distance)

# Returns base cell with rotated quardinates
func get_relative_cell(cell : Vector2i):
	if rotation != 0:
		cell = rotate(rotation, {cell : ["welcome to my life game, said conway", 0]}, [cell])[1][0]
		return cell
	else:
		return cell

# Returns whether or not a certain location is possible for the organism to occupy
func test_valid_location(position : Vector2i, rot = 0):
	var vol : Array
	
	if rot != 0:
		vol = rotate(rot)[1]
	else:
		vol = volume
	
	for i in vol.size():
		if (not O.in_bounds(Vector2i((position.x + vol[i].x) + 500, (position.y + vol[i].y) + 500))) || (O.World[(position.x + vol[i].x) + 500][(position.y + vol[i].y) + 500] != O.TILE["empty"] && O.World[(position.x + vol[i].x) + 500][(position.y + vol[i].y) + 500] != O.TILE["checker"]):
			return false
	return true

# Erases cells from World array
func clear_location():
	var vol : Array
	
	if rotation != 0:
		vol = rotate(rotation)[1]
	else:
		vol = volume
	
	for i in vol.size():
		O.World[(Location.x + vol[i].x) + 500][(Location.y + vol[i].y) + 500] = O.TILE["empty"]

# Uses World array to detect missing pieces and update Form
func update_self():
	var vol : Array
	
	if rotation != 0:
		vol = rotate(rotation)[1]
	else:
		vol = volume
	
	var i = 0
	while i < vol.size():
		if O.World[(Location.x + vol[i].x) + 500][(Location.y + vol[i].y) + 500] != Form[volume[i]][0]:
			Form.erase(volume[i])
			volume.remove_at(i)
			if i != vol.size():
				vol.remove_at(i)
			Stimuli["hurt"] = true
		else:
			i += 1
	
	if !volume.has(Vector2i(0, 0)) || (volume.has(Vector2i(0, 0)) && Form[Vector2i(0, 0)][0] != O.TILE["core"]):
		death()

# Adds self to the World array
func stamp_self():
	var vol : Array
	var folm
	
	if rotation != 0:
		vol = rotate(rotation)[1]
		folm = rotate(rotation)[0]
	else:
		vol = volume
		folm = Form
	
	for i in vol.size():
		O.World[(Location.x + vol[i].x) + 500][(Location.y + vol[i].y) + 500] = folm[vol[i]][0]

# Returns cell directly in front of furthest cell
func get_frontest_cell():
	var front = 0
	
	for i in volume.size():
		if volume[i].x > front && volume[i].y == 0:
			front = volume[i].x
	
	return get_relative_cell(Vector2i(front + 1, 0))

#endregion

func death():
	clear_location()
	O.organs -= volume.size()
	O.Organisms.remove_at(O.Organisms.find(self))
	alive = false

func acepeq(n : int):
	@warning_ignore("narrowing_conversion")
	n = float(n)
	return 1.0 / (1.0 + pow(O.e, (-1.0 * n) / 10.0))
