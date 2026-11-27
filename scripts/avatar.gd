extends Node2D
## Avatar do jogador: anda pela grade com clique/toque, usa óculos de realidade aumentada.

const Bubble = preload("res://scripts/speech_bubble.gd")

var room
var cell := Vector2i.ZERO
var path: Array[Vector2i] = []
var speed := 130.0
var t := 0.0
var walking := false
var facing := 1.0
var nick := "Você"
var jacket := Color(0.13, 0.14, 0.24)
var accent := Color(0.2, 0.9, 1.0)
var skin := Color(0.82, 0.62, 0.48)
var hair := Color(0.12, 0.08, 0.07)
var bubble
var name_label: Label


func setup(r, start: Vector2i) -> void:
	room = r
	cell = start
	position = room.cell_center(start)


func _ready() -> void:
	bubble = Bubble.new()
	bubble.offset_y = -86.0
	add_child(bubble)

	name_label = Label.new()
	name_label.text = nick
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", accent)
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.add_theme_constant_override("outline_size", 4)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(-50, 6)
	name_label.size = Vector2(100, 18)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.z_index = 40
	add_child(name_label)


func walk_to(target: Vector2i) -> void:
	var start: Vector2i = cell
	if not path.is_empty():
		start = path[0]
	var p: Array[Vector2i] = room.find_path(start, target)
	if p.is_empty():
		return
	if path.is_empty():
		p.pop_front()  # remove a casa onde já estamos
	path = p


func say(text: String) -> void:
	bubble.say(text, 4.0)


func hide_bubble() -> void:
	bubble.visible = false


func _process(delta: float) -> void:
	t += delta
	walking = false
	if not path.is_empty():
		walking = true
		var target: Vector2 = room.cell_center(path[0])
		var dx := target.x - position.x
		if absf(dx) > 0.5:
			facing = signf(dx)
		position = position.move_toward(target, speed * delta)
		if position.distance_to(target) < 0.5:
			position = target
			cell = path.pop_front()
	queue_redraw()


func _draw() -> void:
	var bob := 0.0
	var step := 0.0
	if walking:
		bob = -absf(sin(t * 12.0)) * 2.5
		step = sin(t * 12.0) * 4.0
	var lift_l := maxf(step, 0.0) * 0.6
	var lift_r := maxf(-step, 0.0) * 0.6

	# sombra
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 15.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# pernas e tênis com LED
	var pants := Color(0.08, 0.08, 0.12)
	draw_rect(Rect2(-8, -20 + bob, 6, 18 - lift_l), pants)
	draw_rect(Rect2(2, -20 + bob, 6, 18 - lift_r), pants)
	draw_rect(Rect2(-9, -3 - lift_l, 8, 4), Color.WHITE)
	draw_rect(Rect2(1, -3 - lift_r, 8, 4), Color.WHITE)
	draw_line(Vector2(-9, 1 - lift_l), Vector2(-1, 1 - lift_l), accent, 1.5)
	draw_line(Vector2(1, 1 - lift_r), Vector2(9, 1 - lift_r), accent, 1.5)

	# braços, jaqueta
	var arm := jacket.lightened(0.12)
	draw_line(Vector2(-12, -42 + bob), Vector2(-14, -24 + bob + step * 0.5), arm, 5.0)
	draw_line(Vector2(12, -42 + bob), Vector2(14, -24 + bob - step * 0.5), arm, 5.0)
	draw_rect(Rect2(-12, -46 + bob, 24, 28), jacket)
	draw_line(Vector2(-12, -34 + bob), Vector2(12, -34 + bob), accent, 2.0)

	# cabeça + óculos AR
	draw_circle(Vector2(0, -60 + bob), 11.0, hair)
	draw_circle(Vector2(0, -56 + bob), 10.0, skin)
	draw_rect(Rect2(-11 + facing * 2.0, -61 + bob, 22, 6), Color(accent, 0.25))
	draw_rect(Rect2(-9 + facing * 2.0, -60 + bob, 18, 4), accent)
