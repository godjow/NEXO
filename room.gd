extends Node2D
## Loft isométrico: piso, paredes, janela com a cidade lá fora e quadro de arte gerada por IA.
## Também guarda a grade de caminhos (AStarGrid2D).

const TILE_W := 64.0
const TILE_H := 32.0
const WALL_H := 170.0
const CYAN := Color(0.2, 0.9, 1.0)
const PINK := Color(1.0, 0.4, 0.9)

var cols := 12
var rows := 12
var hover := Vector2i(-1, -1)
var astar := AStarGrid2D.new()
var t := 0.0


func _init() -> void:
	z_index = -10
	astar.region = Rect2i(0, 0, cols, rows)
	astar.cell_size = Vector2(1, 1)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()


# ---------- conversões de grade ----------

func iso(g: Vector2) -> Vector2:
	return Vector2((g.x - g.y) * TILE_W * 0.5, (g.x + g.y) * TILE_H * 0.5)


func cell_center(c: Vector2i) -> Vector2:
	return iso(Vector2(c) + Vector2(0.5, 0.5))


func local_to_cell(p: Vector2) -> Vector2i:
	var a := (p.x / (TILE_W * 0.5) + p.y / (TILE_H * 0.5)) * 0.5
	var b := (p.y / (TILE_H * 0.5) - p.x / (TILE_W * 0.5)) * 0.5
	return Vector2i(floori(a), floori(b))


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < cols and c.y < rows


func is_walkable(c: Vector2i) -> bool:
	return in_bounds(c) and not astar.is_point_solid(c)


func set_blocked(c: Vector2i) -> void:
	if in_bounds(c):
		astar.set_point_solid(c, true)


func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if not is_walkable(to) or not in_bounds(from):
		return empty
	return astar.get_id_path(from, to)


# ---------- desenho ----------

func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var up := Vector2(0, -WALL_H)
	var A := iso(Vector2(0, rows))
	var B := iso(Vector2(0, 0))
	var C := iso(Vector2(cols, 0))
	var D := iso(Vector2(cols, rows))

	# paredes
	draw_colored_polygon(PackedVector2Array([A, B, B + up, A + up]), Color(0.08, 0.09, 0.17))
	draw_colored_polygon(PackedVector2Array([B, C, C + up, B + up]), Color(0.11, 0.12, 0.22))
	for i in range(1, rows):
		var p := A.lerp(B, float(i) / rows)
		draw_line(p, p + up, Color(1, 1, 1, 0.03), 1.0)
	for i in range(1, cols):
		var p := B.lerp(C, float(i) / cols)
		draw_line(p, p + up, Color(1, 1, 1, 0.03), 1.0)
	_draw_window(B, C)
	_draw_ai_art(A, B)
	draw_line(A + up, B + up, Color(CYAN, 0.5), 2.0)
	draw_line(B + up, C + up, Color(PINK, 0.5), 2.0)

	# espessura do piso
	var thick := Vector2(0, 14)
	draw_colored_polygon(PackedVector2Array([A, D, D + thick, A + thick]), Color(0.06, 0.06, 0.12))
	draw_colored_polygon(PackedVector2Array([D, C, C + thick, D + thick]), Color(0.09, 0.09, 0.16))

	# ladrilhos
	for x in cols:
		for y in rows:
			var poly := PackedVector2Array([
				iso(Vector2(x, y)), iso(Vector2(x + 1, y)),
				iso(Vector2(x + 1, y + 1)), iso(Vector2(x, y + 1))])
			var col := Color(0.13, 0.14, 0.23) if (x + y) % 2 == 0 else Color(0.11, 0.12, 0.2)
			if Vector2i(x, y) == hover and is_walkable(hover):
				col = Color(0.15, 0.45, 0.55)
			draw_colored_polygon(poly, col)
			poly.append(poly[0])
			draw_polyline(poly, Color(CYAN, 0.07), 1.0)

	# neon no rodapé e na borda
	draw_line(A, B, CYAN, 2.0)
	draw_line(B, C, PINK, 2.0)
	draw_line(A + thick, D + thick, Color(CYAN, 0.35), 1.0)
	draw_line(D + thick, C + thick, Color(CYAN, 0.35), 1.0)


func _draw_window(b: Vector2, c: Vector2) -> void:
	var p0 := b.lerp(c, 0.38)
	var p1 := b.lerp(c, 0.82)
	var y0 := Vector2(0, -45)
	var y1 := Vector2(0, -140)
	draw_colored_polygon(PackedVector2Array([p0 + y0, p1 + y0, p1 + y1, p0 + y1]), Color(0.06, 0.03, 0.16))

	# skyline da cidade
	var n := 16
	for i in n:
		var a0 := p0.lerp(p1, float(i) / n) + y0
		var a1 := p0.lerp(p1, (float(i) + 0.85) / n) + y0
		var h := 18.0 + fmod(float(i) * 37.0, 58.0)
		var bh := Vector2(0, -h)
		draw_colored_polygon(PackedVector2Array([a0, a1, a1 + bh, a0 + bh]), Color(0.12, 0.09, 0.28))
		for k in int(h / 10.0):
			if fmod(float(i * 7 + k * 13), 5.0) < 2.0:
				var wp := a0.lerp(a1, 0.5) + Vector2(0, -6.0 - k * 10.0)
				var wc := Color(1.0, 0.85, 0.4, 0.8) if (i + k) % 3 != 0 else Color(0.3, 0.9, 1.0, 0.8)
				draw_rect(Rect2(wp - Vector2(1.5, 1.5), Vector2(3, 3)), wc)

	# drones de entrega cruzando o céu
	for d in 2:
		var f := fmod(t * 0.06 + d * 0.5, 1.0)
		var dp := p0.lerp(p1, f) + Vector2(0, -128.0 - d * 6.0)
		var blink := 1.0 if fmod(t * 2.0 + d, 1.0) < 0.5 else 0.3
		draw_line(dp + Vector2(-4, 0), dp + Vector2(4, 0), Color(0.7, 0.7, 0.8, 0.8), 1.0)
		draw_circle(dp, 2.0, Color(1.0, 0.3, 0.3, blink))

	var mid := p0.lerp(p1, 0.5)
	draw_line(mid + y0, mid + y1, Color(PINK, 0.4), 1.5)
	draw_polyline(PackedVector2Array([p0 + y0, p1 + y0, p1 + y1, p0 + y1, p0 + y0]), Color(PINK, 0.8), 2.0)


func _draw_ai_art(a: Vector2, b: Vector2) -> void:
	# quadro que muda sozinho, como se fosse arte gerada por IA em tempo real
	var q0 := a.lerp(b, 0.3)
	var q1 := a.lerp(b, 0.7)
	var y0 := Vector2(0, -60)
	var y1 := Vector2(0, -130)
	var strips := 8
	for i in strips:
		var s0 := q0.lerp(q1, float(i) / strips)
		var s1 := q0.lerp(q1, float(i + 1) / strips)
		var hue := fmod(t * 0.04 + float(i) * 0.06, 1.0)
		var mid := Vector2(0, -95.0 + sin(t * 0.8 + i * 0.7) * 12.0)
		draw_colored_polygon(PackedVector2Array([s0 + y0, s1 + y0, s1 + mid, s0 + mid]), Color.from_hsv(hue, 0.65, 0.55))
		draw_colored_polygon(PackedVector2Array([s0 + mid, s1 + mid, s1 + y1, s0 + y1]), Color.from_hsv(fmod(hue + 0.3, 1.0), 0.55, 0.75))
	draw_polyline(PackedVector2Array([q0 + y0, q1 + y0, q1 + y1, q0 + y1, q0 + y0]), Color(0.9, 0.85, 0.6), 2.0)
	draw_string(ThemeDB.fallback_font, q0.lerp(q1, 0.5) + Vector2(-22, -48), "ARTE IA",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.5))
