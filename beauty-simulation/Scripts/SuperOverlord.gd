extends Node

# Modular simplification

var Organisms = []
var World = []
var Ticks = 0

var updates = []
var foods : int = 0
var organs : int = 0

var GRAPHS = []
var modules : int = 1

var e

# Sets e to an approximation of eulers number
func approx_e():
	e = pow((1.0 + (1.0 / 1000000000.0)), 1000000000.0)

const TILE = {
	"empty" : Vector2i(0, 0),
	"wall" : Vector2i(1, 0),
	"food" : Vector2i(2, 0),
	"baser" : Vector2i(0, 1),
	"core" : Vector2i(1, 1),
	"stepper" : Vector2i(2, 1),
	"pivoter" : Vector2i(0, 2),
	"chomper" : Vector2i(1, 2),
	"sniffer" : Vector2i(2, 2),
	"feeler" : Vector2i(0, 3),
	"peeker" : Vector2i(1, 3),
	"checker" : Vector2i(2, 3)
}

const ROTATES = [
	Vector2i(1, 2), #chomper
	Vector2i(2, 2), #sniffer
	Vector2i(0, 3), #feeler
	Vector2i(1, 3) #peeker
]

const ORGANICS = [
	Vector2i(1, 2), #chomper
	Vector2i(2, 2), #sniffer
	Vector2i(0, 3), #feeler
	Vector2i(1, 3), #peeker
	Vector2i(0, 1), #baser
	Vector2i(1, 1), #core
	Vector2i(2, 1), #stepper
	Vector2i(0, 2) #pivoter
]

const MUTATES = [ # Organics excluding core
	Vector2i(1, 2), #chomper
	Vector2i(2, 2), #sniffer
	Vector2i(0, 3), #feeler
	Vector2i(1, 3), #peeker
	Vector2i(0, 1), #baser
	Vector2i(2, 1), #stepper
	Vector2i(0, 2) #pivoter
]

const ACTIONS = [ # Organics which allow actions
	Vector2i(1, 2), #chomper
	Vector2i(2, 1), #stepper
	Vector2i(0, 2) #pivoter
]

const SENSORS = [ # Organics which add stimuli
	Vector2i(2, 2), #sniffer
	Vector2i(0, 3), #feeler
	Vector2i(1, 3), #peeker
]

const VOIDS = [
	Vector2i(0, 0), #empty
	Vector2i(2, 3) #checker
]

var foods_eaten = 0
var organics_eaten = 0
var fake_ticks = 0

# Checks if a tile is within the bounds of the simulation, returns boolean
func in_bounds(cell : Vector2i):
	if cell.x > 999 || cell.x < 0 || cell.y > 999 || cell.y < 0:
		return false
	else:
		return true

func randMute(): # Returns a random orgnaic tile excluding core
	return MUTATES[randi_range(0, MUTATES.size() - 1)]
