extends Node2D
## Móveis "inteligentes" desenhados por código (não precisa de imagens).
## Tipos: sofa, trade, holo, plant, rack

const DESC := {
	"trade": "Estação de trade. Aqui você compra e vende itens com outros jogadores na Bolsa NEXO.",
	"holo": "Holo-globo. Na versão online ele vai mostrar os eventos ao vivo da cidade.",
	"rack": "Seu servidor pessoal. É aqui que eu moro, aliás.",
	"plant": "Planta hidropônica com luz de LED. Zero manutenção, 100% estética.",
	"sofa": "Sofá modular. Com amigos sentados aqui, seu loft ganha reputação.",
}

var room
var kind := "sofa"
var cell := Vector2i.ZERO
var size := Vector2i.ONE
var t := 0.0
var chart: Array = []


func setup(r, k: String, c: Vector2i, s: Vector2i) -> void:
	room = r
	kind = k
	cell = c
	size = s
	position = room.iso(Vector2(c) + Vector2(s) * 0.5)
	t = randf() * 10.0


func describe() -> String:
	return DESC.get(kind, "Objeto do loft.")


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


# retângulo fracionário dentro da área do móvel -> 4 cantos (topo, direita, baixo, esquerda)
func pts(x0: float, y0: float, x1: float, y1: float) -> PackedVector2Array:
	var o := Vector2(cell)
	return PackedVector2Array([
		room.iso(o + Vector2(x0, y0)) - position,
		room.iso(o + Vector2(x1, y0)) - position,
		room.iso(o + Vector2(x1, y1)) - position,
		room.iso(o + Vector2(x0, y1)) - position,
	])


func box(p: PackedVector2Array, h: float, col: Color, lift: float = 0.0) -> void:
	var lo := Vector2(0, -lift)
	var hi := Vector2(0, -lift - h)
	var top := p[0]
	var right := p[1]
	var bottom := p[2]
	var left := p[3]
	draw_colored_polygon(PackedVector2Array([left + lo, bottom + lo, bottom + hi, left + hi]), col.darkened(0.35))
	draw_colored_polygon(PackedVector2Array([bottom + lo, right + lo, right + hi, bottom + hi]), col.darkened(0.15))
	var cap := PackedVector2Array([top + hi, right + hi, bottom + hi, left + hi])
	draw_colored_polygon(cap, col.lightened(0.08))
	cap.append(top + hi)
	draw_polyline(cap, Color(1, 1, 1, 0.12), 1.0)


func _draw() -> void:
	match kind:
		"sofa":
			_draw_sofa()
		"trade":
			_draw_trade()
		"holo":
			_draw_holo()
		"plant":
			_draw_plant()
		"rack":
			_draw_rack()


func _draw_sofa() -> void:
	var col := Color(0.75, 0.2, 0.6)
	var w := float(size.x)
	var d := float(size.y)
	var seat: PackedVector2Array
	if size.x >= size.y:
		box(pts(0.05, 0.05, w - 0.05, 0.35), 34.0, col.darkened(0.2))
		seat = pts(0.05, 0.35, w - 0.05, d - 0.08)
	else:
		box(pts(0.05, 0.05, 0.35, d - 0.05), 34.0, col.darkened(0.2))
		seat = pts(0.35, 0.05, w - 0.08, d - 0.05)
	box(seat, 16.0, col)
	var neon := Color(1.0, 0.5, 0.95)
	draw_line(seat[3] + Vector2(0, -2), seat[2] + Vector2(0, -2), neon, 2.0)
	draw_line(seat[2] + Vector2(0, -2), seat[1] + Vector2(0, -2), neon, 2.0)


func _draw_trade() -> void:
	var green := Color(0.3, 1.0, 0.55)
	# anel pulsando no chão = objeto interativo
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_arc(Vector2.ZERO, 34.0 + sin(t * 3.0) * 3.0, 0.0, TAU, 40, Color(green, 0.55), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	box(pts(0.12, 0.12, 0.88, 0.88), 26.0, Color(0.2, 0.22, 0.32))
	draw_line(Vector2(0, -28), Vector2(0, -46), Color(0.5, 0.5, 0.6), 3.0)
	var r := Rect2(-24, -76, 48, 30)
	draw_rect(r, Color(0.02, 0.05, 0.05))
	draw_rect(r, green, false, 1.5)
	if chart.size() > 1:
		var lo: float = chart.min()
		var hi: float = chart.max()
		var span: float = maxf(hi - lo, 0.001)
		var line := PackedVector2Array()
		for i in chart.size():
			var x := r.position.x + 3.0 + (r.size.x - 6.0) * float(i) / float(chart.size() - 1)
			var y := r.end.y - 4.0 - (r.size.y - 12.0) * (float(chart[i]) - lo) / span
			line.append(Vector2(x, y))
		var going_up: bool = chart[-1] >= chart[0]
		draw_polyline(line, green if going_up else Color(1, 0.35, 0.4), 1.5)
	draw_string(ThemeDB.fallback_font, r.position + Vector2(3, 9), "NX",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(green, 0.8))


func _draw_holo() -> void:
	var cyan := Color(0.3, 0.9, 1.0)
	box(pts(0.2, 0.2, 0.8, 0.8), 8.0, Color(0.15, 0.16, 0.25))
	var flick := 0.75 + 0.25 * sin(t * 17.0) * sin(t * 3.1)
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -8), Vector2(9, -8), Vector2(22, -62), Vector2(-22, -62)]),
		Color(cyan, 0.10 * flick))
	var c := Vector2(0, -78)
	var r := 20.0
	draw_circle(c, r, Color(cyan, 0.08 * flick))
	draw_arc(c, r, 0.0, TAU, 40, Color(cyan, 0.9 * flick), 1.5)
	for k in [-0.5, 0.0, 0.5]:
		var rr: float = r * sqrt(1.0 - k * k)
		draw_set_transform(c + Vector2(0, k * r), 0.0, Vector2(1.0, 0.3))
		draw_arc(Vector2.ZERO, rr, 0.0, TAU, 32, Color(cyan, 0.5 * flick), 1.0)
	for i in 3:
		var sx := absf(cos(t * 1.2 + i * PI / 3.0))
		draw_set_transform(c, 0.0, Vector2(maxf(sx, 0.02), 1.0))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(cyan, 0.5 * flick), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_plant() -> void:
	box(pts(0.28, 0.28, 0.72, 0.72), 16.0, Color(0.22, 0.2, 0.3))
	var sway := sin(t * 1.5) * 1.5
	var g1 := Color(0.2, 0.75, 0.45)
	var g2 := Color(0.3, 0.9, 0.5)
	draw_circle(Vector2(-8 + sway, -26), 8.0, g1)
	draw_circle(Vector2(8 + sway, -28), 8.0, g1)
	draw_circle(Vector2(sway, -36), 9.0, g2)
	draw_circle(Vector2(-4 + sway * 1.3, -46), 6.0, g2)
	var purple := Color(0.8, 0.35, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-12, -62), Vector2(12, -62), Vector2(18, -22), Vector2(-18, -22)]),
		Color(purple, 0.08))
	draw_line(Vector2(0, -62), Vector2(0, -80), Color(0.4, 0.4, 0.5), 1.0)
	draw_line(Vector2(-12, -62), Vector2(12, -62), purple, 3.0)


func _draw_rack() -> void:
	var p := pts(0.15, 0.15, 0.85, 0.85)
	box(p, 74.0, Color(0.1, 0.11, 0.17))
	for row in 7:
		for col in 3:
			var pos := p[2].lerp(p[1], 0.22 + col * 0.28) + Vector2(0, -10.0 - row * 9.0)
			var on := sin(t * (2.0 + col * 1.7 + row * 0.9) + row * col) > 0.0
			var c := Color(0.3, 1.0, 0.55) if (row + col) % 3 != 0 else Color(0.2, 0.9, 1.0)
			draw_circle(pos, 1.8, c if on else Color(c, 0.15))
