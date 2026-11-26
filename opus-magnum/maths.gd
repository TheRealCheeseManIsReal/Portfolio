class_name Maths
extends Resource

static func add(a, b):
	if is_nan(a + b):
		return 0.0
	return a + b

static func subtract(a, b):
	if is_nan(a - b):
		return 0.0
	return a - b

static func multiply(a, b):
	if is_nan(a * b):
		return 0.0
	return a * b

static func divide(a, b):
	if b == 0.0:
		return 0.0
	if is_nan(a / b):
		return 0.0
	return a / b

static func power(a, b):
	if is_nan(pow(a, b)):
		b = floor(1.0 / b)
	return pow(a, b)

static func root(a, b):
	if b == 0.0:
		return 0.0
	if is_nan(pow(a, 1.0/b)) :
		b = 1.0
	return pow(a, 1.0/b)

static func modulo(a, b):
	if b > -0.0001 && b < 0.0001:
		return 0.0
	
	var fa : String = str(a - int(a))
	var fb : String = str(b - int(b))
	
	var ia : int = a * pow(10, fa.length() - 2)
	var ib : int = b * pow(10, fb.length() - 2)
	
	var leng = (fa.length() - 2) if fa.length() > fb.length() else (fb.length() - 2)
	
	return (ia % ib) * pow(0.1, leng)

static func logarithm(a, b):
	if is_nan(log(a) / log(b)):
		return 0.0
	return log(a) / log(b)

static func absolute(a):
	return abs(a)

static func sine(a):
	if is_nan(sin(a)):
		return 0.0
	return sin(a)

static func cosine(a):
	if is_nan(cos(a)):
		return 0.0
	return cos(a)

static func tangent(a):
	if is_nan(tan(a)):
		return 0.0
	return tan(a)

static func negative(a):
	return a * -1.0

static func squart(a):
	if a <= 0.0:
		return 0.0
	return sqrt(a)

static func square(a):
	return pow(a, 2.0)

static func na(a = 0.0, b = 0.0):
	if a == 0.0:
		return b
	else:
		return a
