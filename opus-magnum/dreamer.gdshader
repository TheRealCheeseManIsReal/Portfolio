shader_type canvas_item;

uniform int Equation[401];

uniform highp float maximum = 1.0;
uniform highp float minimum = 0.0;

uniform highp float zoom = 1.0;
uniform vec2 campos = vec2(0.0, 0.0);

uniform vec2 mousepos = vec2(0.0, 0.0);
uniform highp float mdown = 0.0;
uniform highp float rng = 0.0;

uniform bool colour;
uniform sampler2D argeebee;

//shader version of the call_math function
highp float call_math(int f, bool op, highp float a, highp float b) {
	highp float output;
	if (op) {
		switch (f) {
			case 0:
				output = a + b;
				break;
			case 1:
				output = a - b;
				break;
			case 2:
				output = a * b;
				break;
			case 3:
				if (b >= -0.001 && b <= 0.001) {output = 0.0;}
				else {output = a / b;}
				break;
			case 4:
				if (a < 0.0) {output = pow(a * -1.0, b);}
				else {output = pow(a, b);}
				break;
			case 5:
				if (a < 0.0) {output = pow(a * -1.0, 1.0 / b);}
				else {output = pow(a, 1.0 / b);}
				break;
			case 6:
				output = mod(a, b);
				break;
			case 7:
				if (a <= 0.0 || b <= 0.0) {output = 0.0;}
				else {output = log(a) / log(b);}
				break;
		}
	}
	else {
		switch (f) {
			case 0:
				output = abs(a);
				break;
			case 1:
				output = sin(a);
				break;
			case 2:
				output = cos(a);
				break;
			case 3:
				output = tan(a);
				break;
			case 4:
				output = a * -1.0;
				break;
			case 5:
				output = a;
				break;
			case 6:
				output = sqrt(a);
				break;
			case 7:
				output = pow(a, 2.0);
				break;
		}
	}
	
	return output;
}

//shader version of the evaluate function
highp float evaluate(vec2 uv) {
	highp float vars[7] = {((uv.x - 0.5) * zoom + campos.x), ((uv.y - 0.5) * zoom + campos.y), mousepos.x, mousepos.y, mdown, TIME, rng};
	highp float result = call_math(Equation[2], false, vars[Equation[3]], 0.0);
	
	int i = 1;
	highp float b;
	while (Equation[i * 4] != 9) {
		
		if (Equation[i * 4] == 0) {
			result = call_math(Equation[(i * 4) + 2], false, result, 0.0);
			b = vars[Equation[(i * 4) + 3]];
			result = call_math(Equation[(i * 4) + 1], true, b, result);
		}
		else {
			b = call_math(Equation[(i * 4) + 2], false, vars[Equation[(i * 4) + 3]], 0.0);
			result = call_math(Equation[(i * 4) + 1], true, result, b);
		}
		
		i += 1;
	}
	
	return result;
}

void fragment() {
	if (Equation[400] == 0) {
		COLOR.rg = vec2(0.0);
		COLOR.b = 1.0;
	}
	else {
		highp float value = evaluate(UV);
		value = (value - minimum) / (maximum - minimum);
		if (colour){
			vec4 sample = texture(argeebee, vec2(value));
			COLOR = sample;
		}
		else {
			COLOR.rgb = vec3(value);
		}
	}
}
