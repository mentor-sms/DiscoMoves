extends Node2D

# configure:
const demo = false
const uname = "sms"
const poses_on = [0]
var antialiasing = true
const board_size = Vector2(1024, 600)

# don't configure
const test_tries_limit = 10
const camL = 0
const camR = 2

# don't touch:
var wc:WallieController = null
var _elapsed = 0
var _poses
var _step = 0
var _multi = Vector2(0.75, 0.75)
var _move = Vector2(0, 0)
var _pre = Vector2(0, 0)
var _hide_timer = 5
var _margin = 0
var _setup_timer = 0

var lhandp = Vector2(0, 0)
var rhandp = Vector2(0, 0)
var lfootp = Vector2(0, 0)
var rfootp = Vector2(0, 0)
var assp = Vector2(0, 0)
var neckp = Vector2(0, 0)
var torsop = Vector2(0, 0)
var larm = PoolVector2Array()
var rarm = PoolVector2Array()
var lleg = PoolVector2Array()
var rleg = PoolVector2Array()

func _input(ev):
	if ev is InputEventKey:
		if ev.scancode == 61:
			_multi.x += 0.1
			_multi.y += 0.1
		if ev.scancode == KEY_MINUS:
			_multi.x -= 0.1
			_multi.y -= 0.1
		if ev.scancode == KEY_UP:
			_move.y -= 1
		if ev.scancode == KEY_DOWN:
			_move.y += 1
		if ev.scancode == KEY_LEFT:
			_move.x -= 1
		if ev.scancode == KEY_RIGHT:
			_move.x += 1

var _cam_pairs = PoolVector2Array()
var _cam_pairs_idx = 0
var _cam_pairs_testing = false
var _cam_test_tries = 0
func _process(delta):
	_elapsed += delta
	
	var shape_detected = false
	
	if _step == 0:
		if not _cam_pairs_testing:
			_elapsed = 0
			wc = null
			wc = WallieController.new()
			var pair = _cam_pairs[_cam_pairs_idx]
			if wc.initSGBMByIdx(pair.x, pair.y):
				_cam_pairs_testing = true
			else:
				_cam_pairs_idx += 1
				if _cam_pairs_idx >= _cam_pairs.size():
					_cam_pairs_idx = 0
		else:
			if _elapsed > 0.01:
				_elapsed = 0
				wc.tick()
			shape_detected = wc.wasShapeDetected()
			if shape_detected:
				calc()
				_step = 1
			else:
				if _cam_test_tries < test_tries_limit:
					_cam_test_tries += 1
				else:
					_cam_pairs_testing = false
	elif _step >= 1:
		shape_detected = wc.wasShapeDetected()
		if shape_detected:
			_hide_timer = 0
			if wc.build2DKeypoints([0]):
				var idx = -1
				for pid in poses_on:
					idx = idx + 1
					if wc.check2DPose(pid):
						_poses[idx] = true
					else:
						_poses[idx] = false
				calc()
			else:
				_step = -1
				return
			
			if _poses[0]:
				var a = lhandp.y > assp.y and rhandp.y > assp.y
				var b = lfootp.x < lfootp.y
				var c = lhandp.x < larm[2].x and rhandp.x > rarm[2].x
				if a and b and c:
					_step = 2
					_setup_timer = 0
				
		else:
			_hide_timer += delta
			calc()
		
		if shape_detected:
			if _step == 1:
				_test_pose()
			elif _step == 2:
				_setup_timer += delta
				var secs = int(3 - _setup_timer)
				if secs < 0:
					$SetupTimerLabel.visible = false
					
					var screenctr = Vector2(board_size.x / 2, board_size.y / 2)
					var mvx = (board_size.x / 2) - torsop.x
					var mvy = board_size.y - 10 - wc.calc2DCentre([lleg[1], rleg[1]]).y
					_move.x += mvx
					_move.y += mvy
					
					calc()
					_build_def_pose()
					
					_step = 1
				else:
					$SetupTimerLabel.text = String(secs)
					$SetupTimerLabel.visible = true
			
		if _elapsed > 0.01:
			_elapsed = 0
			wc.tick()

func _ready():
	randomize()
	
	for c0 in range(0, 4):
		for c1 in range(0, 4):
			if c0 != c1:
				_cam_pairs.append(Vector2(c0, c1))
				
	_poses = [false]
	_poses.clear()
	for _i in range(0, poses_on.size()):
		_poses.append(false)
		
	_margin = int((board_size.x - board_size.y) / 2)
	
	if demo:
		wc = WallieController.new()
		if wc.initSGBMWithDemo(0, "sms"):
			calc()
			_step = 1
		else:
			_step = -1
	else:
		wc = WallieController.new()
		if wc.initSGBMByIdx(camL, camR):
			calc()
			_step = 1
		else:
			_step = -1

var _curr_pose_id = 0
func draw_pose(pose_id):
	if _curr_pose_id == 0:
		pass
	elif _curr_pose_id == 1:
		pass

func calc():
	lhandp = wc.calc2DCentre(wc.take2DKeypoints(13, _multi, _move, _pre))
	rhandp = wc.calc2DCentre(wc.take2DKeypoints(14, _multi, _move, _pre))
	lfootp = wc.calc2DCentre(wc.take2DKeypoints(15, _multi, _move, _pre))
	rfootp = wc.calc2DCentre(wc.take2DKeypoints(16, _multi, _move, _pre))
	
	larm = wc.take2DKeypoints(2, _multi, _move, _pre)
	rarm = wc.take2DKeypoints(3, _multi, _move, _pre)
	lleg = wc.take2DKeypoints(4, _multi, _move, _pre)
	rleg = wc.take2DKeypoints(5, _multi, _move, _pre)
	
	var ass = wc.take2DKeypoints(1, _multi, _move, _pre)
	torsop = wc.calc2DCentre(ass)
	var neck = ass
	ass.remove(0)
	ass.remove(0)
	neck.remove(neck.size() - 1)
	neck.remove(neck.size() - 1)
	assp = wc.calc2DCentre(ass)
	neckp = wc.calc2DCentre(neck)
	
	var h = assp.y - neckp.y
	h = h / 4.0
	assp.y = assp.y - h
	neckp.y = neckp.y + h
	
	update()


func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
	var q0 = p0.linear_interpolate(p1, t)
	var q1 = p1.linear_interpolate(p2, t)
	var r = q0.linear_interpolate(q1, t)
	return r
	
func rangef(start: float, end: float, step: float):
	var res = Array()
	var i = start
	while i < end:
		res.push_back(i)
		i += step
	return res
	
func _draw_curve(p0: Vector2, p1: Vector2, p2: Vector2, color: Color, width: float, aa: bool, max_stages: int = 5, tolerance_degrees: float = 4):
	var curve = Curve2D.new()
	
	for step in rangef(0, 1, 0.1):
		curve.add_point(_quadratic_bezier(p0, p1, p2, step))
		
	var pts = curve.tessellate(max_stages, tolerance_degrees)
	for idx in range(1, pts.size()):
		draw_line(pts[idx - 1], pts[idx], color, width, aa)

var larm0p:Vector2 = Vector2()
var rarm0p:Vector2 = Vector2()
var army = 0
var segl = 0
var segl_2 = 0
var segl_4 = 0
var larmrs = [Rect2(), Rect2(), Rect2()]
var rarmrs = [Rect2(), Rect2(), Rect2()]
func _build_def_pose():
	var larml = larm[2].x - larm[0].x
	var rarml = rarm[0].x - rarm[2].x
	var arml = (larml + rarml) / 2
	segl = int(arml / 2)
	segl_2 = int(segl / 2)
	segl_4 = int(segl_2 / 2)
	army = int((larm[0].y + rarm[0].y) / 2)
	
	larm0p = larm[0]
	rarm0p = rarm[0]
	print("sizes: ", larm0p, " ", segl)
	
	larmrs[0] = Rect2(Vector2(larm0p.x - segl_4, army - segl_2), Vector2(segl, segl))
	larmrs[1] = Rect2(Vector2(larm0p.x + segl - segl_4, army - segl_2), Vector2(segl, segl))
	larmrs[2] = Rect2(Vector2(larm0p.x + 2*segl - segl_4, army - segl_2), Vector2(segl, segl))
	
	rarmrs[0] = Rect2(Vector2(rarm0p.x - segl + segl_4, army - segl_2), Vector2(segl, segl))
	rarmrs[1] = Rect2(Vector2(rarm0p.x - 2*segl + segl_4, army - segl_2), Vector2(segl, segl))
	rarmrs[2] = Rect2(Vector2(rarm0p.x - 3*segl + segl_4, army - segl_2), Vector2(segl, segl))
	
	update()
	
func _build_random_pose():
	var r1r = randi() % 3 + 0
	var vec = rarmrs[0].position
	var poss = Array()
	if r1r == 0:
		vec.y += segl
		poss = [0, 1]
	elif r1r == 1:
		vec.x -= segl
		poss = [0, 1, 2]
	elif r1r == 2:
		vec.y -= segl
		poss = [1, 2]
		
	rarmrs[1] = Rect2(vec, Vector2(segl, segl))
	
	var r2r = poss[randi() % poss.size()]
	if r2r == 0:
		vec.y += segl - segl_4
	if r2r == 1:
		vec.x -= segl - segl_4
	if r2r == 2:
		vec.y -= segl - segl_4
		
	rarmrs[2] = Rect2(vec, Vector2(segl, segl))
	
	var l1r = randi() % 3 + 0
	vec = larmrs[0].position
	if l1r == 0:
		vec.y += segl
		poss = [0, 1]
	elif l1r == 1:
		vec.x += segl
		poss = [0, 1, 2]
	elif l1r == 2:
		vec.y -= segl
		poss = [1, 2]
		
	larmrs[1] = Rect2(vec, Vector2(segl, segl))
	
	var l2r = poss[randi() % poss.size()]
	if l2r == 0:
		vec.y += segl - segl_4
	if l2r == 1:
		vec.x += segl - segl_4
	if l2r == 2:
		vec.y -= segl - segl_4
		
	larmrs[2] = Rect2(vec, Vector2(segl, segl))
	
	update()

var rarmbs = [false, true, false]
var larmbs = [false, true, false]
func _test_pose():
	rarmbs[0] = rarmrs[0].has_point(rarm[0])
	rarmbs[2] = rarmrs[2].has_point(rarm[2])
	larmbs[0] = larmrs[0].has_point(larm[0])
	larmbs[2] = larmrs[2].has_point(larm[2])
	if not larmbs.has(false) and not rarmbs.has(false):
		_build_random_pose()


var mcolor = Color(0, 1, 0)
var lcolor = Color(0, 0, 1)
var rcolor = Color(1, 0, 0)
var goodc = Color(0, 1, 0)

func _draw():
	if _step == 0:
		pass
	elif _step >= 1:
		var linew = 5 - int(_hide_timer)
		if linew < 0:
			linew = 0
		if linew != 0:
			_draw_curve(larm[0], larm[1], larm[2], lcolor, linew, antialiasing)
			_draw_curve(rarm[0], rarm[1], rarm[2], rcolor, linew, antialiasing)
			_draw_curve(lleg[0], lleg[1], lleg[2], mcolor, linew, antialiasing)
			_draw_curve(rleg[0], rleg[1], rleg[2], mcolor, linew, antialiasing)
			draw_line(larm[2], lhandp, lcolor, linew, antialiasing)
			draw_line(rarm[2], rhandp, rcolor, linew, antialiasing)
			draw_line(lleg[2], lfootp, mcolor, linew, antialiasing)
			draw_line(rleg[2], rfootp, mcolor, linew, antialiasing)
			_draw_curve(lleg[0], assp, rleg[0], mcolor, linew, antialiasing)
			_draw_curve(larm[0], neckp, rarm[0], mcolor, linew, antialiasing)
			#draw_circle(lhandp, linew + 2, lcolor)
			#draw_circle(rhandp, linew + 2, rcolor)
			#draw_circle(lfootp, linew + 2, lcolor)
			#draw_circle(rfootp, linew + 2, rcolor)
			_draw_curve(larm[0], torsop, assp, mcolor, linew, antialiasing)
			_draw_curve(rarm[0], torsop, assp, mcolor, linew, antialiasing)
		
		for i in range(0, 3):
			if i != 1:
				if rarmrs[i].size.x > 0:
					var clr
					if rarmbs[i]:
						clr = goodc
					else:
						clr = rcolor
					draw_rect(rarmrs[i], clr, false, 1, antialiasing)
				if larmrs[i].size.x > 0:
					var clr
					if larmbs[i]:
						clr = goodc
					else:
						clr = lcolor
					draw_rect(larmrs[i], clr, false, 1, antialiasing)
			
