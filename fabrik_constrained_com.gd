extends Node2D

# limb storage indexes, self explanatory
enum {
	LIMB_LEN,
	LIMB_MIN,
	LIMB_MAX
}
# used to calculate how ik misses the target
const BIAS = 3
const ITERATIONS = 32

# self explanatory
var base_point = Vector2(140, 135)
# lengths of every limb in px, minimum and maximum angle constraints
var limbs := [
	[80, -deg_to_rad(65), deg_to_rad(65)],
	[60, -deg_to_rad(65), deg_to_rad(65)],
	[80, -deg_to_rad(65), deg_to_rad(65)],
]
# the points we working with
var joints := PackedVector2Array()

# just to not call limbs.size() every time
var limbs_size := 0
# used to calculate target overshoot from possible range
var limbs_len := 0

# amount of lerp from old joints to new, 1.0 disables lerp completely
var lerp_amount := 0.5

# new general update function introduced to handle lerping and
# case, when target is too close to base point for constrained ik
func update(target: Vector2) -> void:
	# storing old joints before calculating new ones
	var joints_p := joints.duplicate()
	# updating ik, and getting squared (faster to calculate)
	# distance between last joint and target
	var dist := update_ik(target)

	# check if we out of target - that happens when ik is constrained
	# and target is too close to the base_point
	# since we receiving distance squared - comparing with BIAS squared
	if dist > BIAS * BIAS:
		# reset joints to the old ones
		joints = joints_p
		# call update_ik again with target as target, 
		# but pulled out to distance to last joint, so it's
		# possible to reach, and it is possibly close to desired target
		@warning_ignore(return_value_discarded)
		update_ik(
			base_point + (target - base_point).normalized() *
			(base_point.distance_to(joints[limbs_size]))
		)
		return
		
	# if lerp is not 1.0 (which is the same as not doing anything) -
	# lerp between old and new joints
	if lerp_amount != 1.0:
		for i in range(limbs_size + 1):
			joints[i] = joints_p[i].lerp(joints[i], lerp_amount)

func update_ik(target: Vector2) -> float:
	# distance between last joint and target storage,
	# first init used for calculation of target overshoot from possible range
	var dist := base_point.distance_squared_to(target)
	var iterations := 0
	
	# if target is far from range we can use only one iteration
	if dist > limbs_len * limbs_len:
		_backward_pass(target)
		_forward_pass()
		return 0.0
	
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
	
	return joints[limbs_size].distance_squared_to(target)

func _forward_pass() -> void:
	# define root_angle var outside the loop, since we can
	# don't calculate it and just set it at the end of iteration
	# to the angle
	var root_angle := 0.0
	# force setting first point to the base_point,
	# due backward passing most likely didn't land it there
	joints[0] = base_point
	# for every limb, as well for every joint pair for that limb (i and i + 1)
	for i in range(limbs_size):
		var limb := limbs[i]
		var a := joints[i]
		var b := joints[i + 1]
		# calculating difference between current pair of points
		# by subtracting the base angle of previous pair
		# and wrap it to -PI, PI for good
		# (avoid that matrix math stuff at any cost)
		var diff_angle_raw := wrapf(a.angle_to_point(b) - root_angle, -PI, PI)
		# clamp that difference angle to min/max of current limb
		var diff_angle := clampf(
				diff_angle_raw, limb[LIMB_MIN], limb[LIMB_MAX]
		)
		# angle now is sum of the root angle for previous pair
		# and current clamped difference angle
		var angle := root_angle + diff_angle
		
		# set limb end's joint to start + rotated length of that limb
		joints[i + 1] = a + Vector2(limb[LIMB_LEN], 0).rotated(angle)
		# set the root angle for the next iteration
		root_angle = angle

func _backward_pass(target: Vector2) -> void:
	# force setting last point to the target point,
	# so we can go backwards to base_point approx
	# note that joints size is limbs size + 1
	joints[limbs_size] = target
	# for every limb, as well for every joint pair
	# for that limb (i and i - 1) backwards
	for i in range(limbs_size, 0, -1):
		var limb := limbs[i - 1]
		# this is the first point from the END
		var a := joints[i]
		# this is the second point from the END
		var b := joints[i - 1]
		# this is the third point from the END
		# or base point, if we bound to the joints begin
		# it needed for root_angle calculation from the back
		var c := joints[i - 2] if i > 1 else base_point
		var root_angle := c.angle_to_point(b)
		# calculating difference between current pair of points
		# by subtracting the base angle of... next pair, since we are
		# going backwards
		var diff_angle_raw := b.angle_to_point(a) - root_angle
		# clamp that difference angle to min/max of current limb
		var diff_angle := clampf(
				diff_angle_raw, limb[LIMB_MIN], limb[LIMB_MAX]
		)
		# angle now is sum of the root angle for next pair
		# and current clamped difference angle
		var angle := root_angle + diff_angle
		
		# set limb start's joint to end + rotated length of that limb + PI
		# since we are calculating angles from the end
		joints[i - 1] = a + Vector2(limb[LIMB_LEN], 0).rotated(angle + PI)

func _ready():
	limbs_size = limbs.size()
	@warning_ignore(return_value_discarded)
	# joints size is limbs size + 1
	joints.resize(limbs_size + 1)
	# it's nice to have a solved ik that is not looking at the Vector2.ZERO point
	# so we just making straight line out of limbs lengths from base_point
	joints[0] = base_point
	for i in range(limbs_size):
		limbs_len += limbs[i][LIMB_LEN]
		joints[i + 1] = joints[i] + Vector2(limbs[i][LIMB_LEN], 0)

func _process(_delta):
	update(get_global_mouse_position())
	queue_redraw()

func _draw():
	for i in range(limbs_size + 1):
		if i > 0:
			draw_line(joints[i - 1], joints[i], Color.WEB_GRAY, 1)
			# kinda messy hint drawing of the constraints
			draw_line(
					joints[i - 1], joints[i - 1] + (
						(joints[i - 1] - joints[i - 2]) if i > 1 else Vector2.RIGHT
					).rotated(limbs[i - 1][LIMB_MIN]).normalized() * 32,
					Color.DARK_GOLDENROD, 0.5
			)
			draw_line(
					joints[i - 1], joints[i - 1] + (
						(joints[i - 1] - joints[i - 2]) if i > 1 else Vector2.RIGHT
					).rotated(limbs[i - 1][LIMB_MAX]).normalized() * 32,
					Color.DARK_GOLDENROD, 0.5
			)
	for i in range(limbs_size + 1):
		draw_circle(joints[i], 2, Color.WHITE)
