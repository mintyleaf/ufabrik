extends Node2D

const ITERATIONS = 32

# iteration benchmark, can be removed
@onready var info: Label = $info

# self explanatory
var base_point = Vector2(140, 135)
# lengths of every limb in px
var limbs := [
	80,
	60,
	80,
]
# the points we working with
var joints := PackedVector2Array()
# just to not call limbs.size() every time
var limbs_size := 0
# used to calculate target overshoot from possible range
var limbs_len := 0

# iteration benchmark, can be removed
var all_iterations := 0
var iterations_count := 0

func update_ik(target: Vector2) -> void:
	# distance between last joint and target storage,
	# first init used for calculation of target overshoot from possible range
	var dist := base_point.distance_squared_to(target)
	var iterations := 0
	
	# if target is far from range we can use only one iteration
	if dist > limbs_len * limbs_len:
		_backward_pass(target)
		_forward_pass()
		# for iteration benchmark purposes, can be removed
		iterations = 1
		# return
	# without benchmark the whole underneath block
	# can be flattened one tab down instead of else branch
	else:
		# minimal distance between last joint and target storage
		var min_dist := INF
		var min_joints: PackedVector2Array
		while iterations < ITERATIONS:
			_backward_pass(target)
			_forward_pass()
			iterations += 1
			# distance between last joint and target
			dist = joints[limbs_size].distance_squared_to(target)
			# if last joint near target point it can start to "vibrate"
			# so if current distance is greater than minimal -
			# we know that we are pretty close to the target and can
			# safely break the loop
			if min_dist > dist:
				min_dist = dist
				# store all the minimal joints states,
				# so we can restore them when overshoot
				min_joints = joints.duplicate()
			else:
				break
		
		# restoring from overshooted joints to last minimal ones
		if dist > min_dist:
			joints = min_joints
	
	# iterations benchmark, can be removed
	all_iterations += iterations
	iterations_count += 1
	@warning_ignore(integer_division)
	info.text = str(all_iterations / iterations_count)

func _forward_pass() -> void:
	# force setting first point to the base_point,
	# due backward passing most likely didn't land it there
	joints[0] = base_point
	# for every limb, as well for every joint pair for that limb (i and i + 1)
	for i in range(limbs_size):
		var a := joints[i]
		var b := joints[i + 1]
		var angle := a.angle_to_point(b)
		
		# set limb end's joint to start + rotated length of that limb
		joints[i + 1] = a + Vector2(limbs[i], 0).rotated(angle)

func _backward_pass(target: Vector2) -> void:
	# force setting last point to the target point,
	# so we can go backwards to base_point approx
	# note that joints size is limbs size + 1
	joints[limbs_size] = target
	# for every limb, as well for every joint pair
	# for that limb (i and i - 1) backwards
	for i in range(limbs_size, 0, -1):
		var a := joints[i]
		var b := joints[i - 1]
		var angle := a.angle_to_point(b)
		
		# set limb start's joint to end + rotated length of that limb
		joints[i - 1] = a + Vector2(limbs[i - 1], 0).rotated(angle)

func _ready():
	limbs_size = limbs.size()
	@warning_ignore(return_value_discarded)
	# joints size is limbs size + 1
	joints.resize(limbs_size + 1)
	# it's nice to have a solved ik that is not looking at the Vector2.ZERO point
	# so we just making straight line out of limbs lengths from base_point
	joints[0] = base_point
	for i in range(limbs_size):
		limbs_len += limbs[i]
		joints[i + 1] = joints[i] + Vector2(limbs[i], 0)

func _process(_delta):
	update_ik(get_global_mouse_position())
	queue_redraw()

func _draw():
	for i in range(limbs_size + 1):
		if i > 0:
			draw_line(joints[i - 1], joints[i], Color.WEB_GRAY, 1)
	for i in range(limbs_size + 1):
		draw_circle(joints[i], 2, Color.WHITE)
