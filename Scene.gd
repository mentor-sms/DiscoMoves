extends Node2D

var inited = false
var wc

var lhand = Vector2(0, 0)
var rhand = Vector2(0, 0)

var larm = PoolVector2Array()
var rarm = PoolVector2Array()
var lua = 0
var lba = 0
var rua = 0
var rba = 0

var lshape = 0
var rshape = 0

var score = 0
var combo = 0

var elapsed = 0

func _ready():
	if not ClassDB.can_instance("WallieController"):
		return
	wc = WallieController.new()
	if wc.initBMWithDemo(0, "sms"):
		calc()
		inited = true

const multi = Vector2(0.75, 0.75)
const move = Vector2(350, 200)
const pre = Vector2(0, 0)

func angles2shape(ua, ba, left):
	if ua > 0 and ua < 20: # arm straight down
		if ba > 0 and ba < 20:
			return 10 # up
		if ba > 85 and ba < 95:
			return 11 # away
		if ba > 175 and ba < 185:
			return 12 # straight down
		if ba > 265 and ba < 275:
			return 13 # inside
		return -1
	if ua > 85 and ua < 95: # arm away
		if ba > 0 and ba < 20:
			return 20 # biceps
		if ba > 85 and ba < 95:
			return 21 # power pose
		if ba > 175 and ba < 185:
			return 22 # straight away
		if ba > 265 and ba < 275:
			return 23 # gorilla
		return -2
	if ua > 175 and ua < 185: # arm up
		if ba > 0 and ba < 20:
			return 30 # behind head
		if ba > 85 and ba < 95:
			return 31 # above head
		if ba > 175 and ba < 185:
			return 32 # straight up
		return -3
	return -4

func calc():
	lhand = wc.calc2DCentre(wc.take2DKeypoints(6, multi, move, pre))
	rhand = wc.calc2DCentre(wc.take2DKeypoints(7, multi, move, pre))
	
	larm = wc.take2DKeypoints(2, multi, move, pre)
	rarm = wc.take2DKeypoints(3, multi, move, pre)
	
	var torso = wc.take2DKeypoints(1, multi, move, pre)
	torso.remove(0)
	torso.remove(0)
	var ass = wc.calc2DCentre(torso)
	
	lua = wc.calc2DAngle(larm[0], Vector2(larm[0].x, ass.y), larm[1])
	lba = wc.calc2DAngle(larm[1], larm[0], larm[2])
	rua = wc.calc2DAngle(rarm[0], Vector2(rarm[0].x, ass.y), rarm[1])
	rba = wc.calc2DAngle(rarm[1], rarm[0], rarm[2])
	
	var olshape = lshape
	lshape = angles2shape(lua, lba, true)
	var orshape = rshape
	rshape = angles2shape(rua, rba, false)
		
	if (olshape != lshape and lshape > 0) or (orshape != rshape and rshape > 0):
		print(lshape, " ", rshape)

func _process(delta):
	if not inited:
		return
	elapsed += delta
	
	if wc.wasShapeDetected():
		if wc.build2DKeypoints():
			calc()
			update()
		else:
			inited = false
			return
	
	if elapsed > 0.04:
		elapsed = 0
		wc.tick()
		
func draw_stickfig(pos, ):
	
	
func _draw():
	draw_circle(lhand, 10, Color(1, 0, 0))
	draw_circle(rhand, 10, Color(0, 0, 1))
	draw_line(larm[0], larm[1], Color(1, 0, 0))
	draw_line(larm[1], larm[2], Color(1, 0, 0))
	draw_line(rarm[0], rarm[1], Color(0, 0, 1))
	draw_line(rarm[1], rarm[2], Color(0, 0, 1))
