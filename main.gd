extends Node2D
## NEXO — protótipo fase 1
## Loft isométrico, avatar com clique/toque, IA companheira (Eco) e Bolsa de itens simulada.

const RoomS = preload("res://scripts/room.gd")
const AvatarS = preload("res://scripts/avatar.gd")
const EcoS = preload("res://scripts/eco.gd")
const FurnitureS = preload("res://scripts/furniture.gd")

const ACCENT := Color(0.2, 0.9, 1.0)
const PINK := Color(1.0, 0.4, 0.9)
const GREEN := Color(0.3, 1.0, 0.55)
const RED := Color(1.0, 0.35, 0.4)
const GOLD := Color(1.0, 0.85, 0.3)

var world: Node2D
var room
var entities: Node2D
var player
var eco
var furniture_list: Array = []

# Economia local (na fase 3 tudo isso passa a morar no servidor)
var coins := 1250.0
var market: Array = [
	{"name": "Holo-Sofá Ed.1", "price": 120.0, "change": 0.0, "owned": 0},
	{"name": "Drone Pet", "price": 340.0, "change": 0.0, "owned": 0},
	{"name": "Planta Neon", "price": 45.0, "change": 0.0, "owned": 0},
	{"name": "Quadro IA #042", "price": 890.0, "change": 0.0, "owned": 0},
	{"name": "Tênis Holo", "price": 210.0, "change": 0.0, "owned": 0},
]
var base_total := 0.0
var index_history: Array = []
var market_timer := 0.0
var eco_timer := 30.0

# UI
var coins_label: Label
var worth_label: Label
var market_panel: PanelContainer
var market_rows: Array = []
var chat_input: LineEdit
var chat_log: RichTextLabel
var log_lines: Array = []


func _ready() -> void:
	randomize()
	world = Node2D.new()
	world.position = Vector2(640, 232)
	add_child(world)

	room = RoomS.new()
	world.add_child(room)

	entities = Node2D.new()
	entities.y_sort_enabled = true
	world.add_child(entities)

	_spawn_furniture()

	player = AvatarS.new()
	player.setup(room, Vector2i(6, 7))
	entities.add_child(player)

	eco = EcoS.new()
	eco.follow = player
	entities.add_child(eco)

	for item in market:
		base_total += item["price"]
	for i in 40:
		index_history.append(100.0)

	_build_hud()
	_refresh_market_ui()
	get_tree().create_timer(1.2).timeout.connect(_greet)


func _greet() -> void:
	_eco_say("Oi! Eu sou a Eco, sua IA. Toque no chão pra andar e na mesa verde pra abrir a Bolsa.")


func _spawn_furniture() -> void:
	var layout := [
		["rack", Vector2i(0, 0), Vector2i(1, 1)],
		["sofa", Vector2i(3, 0), Vector2i(2, 1)],
		["plant", Vector2i(11, 0), Vector2i(1, 1)],
		["sofa", Vector2i(0, 4), Vector2i(1, 2)],
		["plant", Vector2i(0, 9), Vector2i(1, 1)],
		["trade", Vector2i(9, 3), Vector2i(1, 1)],
		["holo", Vector2i(5, 4), Vector2i(1, 1)],
	]
	for entry in layout:
		var f = FurnitureS.new()
		f.setup(room, entry[0], entry[1], entry[2])
		f.chart = index_history
		entities.add_child(f)
		furniture_list.append(f)
		for x in range(entry[2].x):
			for y in range(entry[2].y):
				room.set_blocked(entry[1] + Vector2i(x, y))


# ---------- loop ----------

func _process(delta: float) -> void:
	market_timer += delta
	if market_timer >= 1.5:
		market_timer = 0.0
		_tick_market()
	eco_timer -= delta
	if eco_timer <= 0.0:
		eco_timer = randf_range(28.0, 45.0)
		_eco_say(eco.random_tip())


func _tick_market() -> void:
	var total := 0.0
	for item in market:
		var pct := randf_range(-0.035, 0.04)
		item["price"] = maxf(5.0, item["price"] * (1.0 + pct))
		item["change"] = pct
		total += item["price"]
	index_history.append(total / base_total * 100.0)
	if index_history.size() > 40:
		index_history.pop_front()
	_refresh_market_ui()


# ---------- input do mundo ----------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		room.hover = room.local_to_cell(world.get_local_mouse_position())
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().gui_release_focus()
		var c: Vector2i = room.local_to_cell(world.get_local_mouse_position())
		var f = _furniture_at(c)
		if f != null:
			var spot := _free_spot_near(f)
			if spot.x >= 0:
				player.walk_to(spot)
			_eco_say(f.describe())
			if f.kind == "trade":
				_toggle_market(true)
		elif room.is_walkable(c):
			player.walk_to(c)


func _furniture_at(c: Vector2i):
	for f in furniture_list:
		if c.x >= f.cell.x and c.x < f.cell.x + f.size.x and c.y >= f.cell.y and c.y < f.cell.y + f.size.y:
			return f
	return null


func _free_spot_near(f) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := INF
	var pc: Vector2i = player.cell
	var from := Vector2(pc)
	for x in range(f.cell.x - 1, f.cell.x + f.size.x + 1):
		for y in range(f.cell.y - 1, f.cell.y + f.size.y + 1):
			var c := Vector2i(x, y)
			if room.is_walkable(c):
				var d := from.distance_to(Vector2(c))
				if d < best_d:
					best_d = d
					best = c
	return best


# ---------- chat ----------

func _on_chat(text: String) -> void:
	text = text.strip_edges()
	if text.is_empty():
		return
	chat_input.clear()
	chat_input.release_focus()
	player.say(text)
	_log("Você", text, ACCENT)
	if text.to_lower().contains("eco"):
		var r: String = eco.reply(text, market)
		get_tree().create_timer(1.0).timeout.connect(func(): _eco_say(r))


func _eco_say(text: String) -> void:
	player.hide_bubble()
	eco.say(text)
	_log("Eco", text, PINK)


func _log(who: String, text: String, col: Color) -> void:
	log_lines.append("[color=#%s]%s:[/color] %s" % [col.to_html(false), who, text.replace("[", "[lb]")])
	if log_lines.size() > 5:
		log_lines.pop_front()
	chat_log.text = "\n".join(log_lines)


# ---------- Bolsa NEXO ----------

func _buy(i: int) -> void:
	var item: Dictionary = market[i]
	if coins < item["price"]:
		_eco_say("Saldo insuficiente pra %s. Vende algo ou espera o preço cair." % item["name"])
		return
	coins -= item["price"]
	item["owned"] += 1
	item["price"] *= 1.02  # demanda empurra o preço pra cima
	_refresh_market_ui()


func _sell(i: int) -> void:
	var item: Dictionary = market[i]
	if item["owned"] <= 0:
		_eco_say("Você ainda não tem %s pra vender." % item["name"])
		return
	coins += item["price"] * 0.97  # taxa de 3% do mercado
	item["owned"] -= 1
	item["price"] *= 0.985  # oferta empurra o preço pra baixo
	_refresh_market_ui()


func _toggle_market(open: bool) -> void:
	market_panel.visible = open


func _refresh_market_ui() -> void:
	var worth := coins
	for i in market.size():
		var item: Dictionary = market[i]
		worth += item["price"] * item["owned"]
		if i < market_rows.size():
			var r: Dictionary = market_rows[i]
			var pct: float = item["change"] * 100.0
			r["price"].text = "NX$ %.0f" % item["price"]
			r["change"].text = "%+.1f%%" % pct
			r["change"].add_theme_color_override("font_color", GREEN if pct >= 0.0 else RED)
			r["owned"].text = "x%d" % item["owned"]
	coins_label.text = "NX$ %.0f" % coins
	worth_label.text = "Patrimônio NX$ %.0f" % worth


# ---------- HUD ----------

func _style(bg: Color, border: Color, radius: int = 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	return sb


func _label(text: String, col: Color = Color.WHITE, font_size: int = 16) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", font_size)
	return l


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)

	# barra do topo
	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", _style(Color(0.03, 0.04, 0.09, 0.9), Color(ACCENT, 0.4), 0))
	top.anchor_right = 1.0
	top.offset_bottom = 48.0
	hud.add_child(top)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 16)
	top.add_child(bar)
	bar.add_child(_label("NEXO   ·   Loft 27-B   ·   Distrito Neon", ACCENT))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	worth_label = _label("", Color(0.7, 0.75, 0.85), 14)
	bar.add_child(worth_label)
	coins_label = _label("", GOLD)
	bar.add_child(coins_label)
	var bolsa_btn := Button.new()
	bolsa_btn.text = "Bolsa NEXO"
	bolsa_btn.pressed.connect(func(): _toggle_market(not market_panel.visible))
	bar.add_child(bolsa_btn)

	# log do chat
	chat_log = RichTextLabel.new()
	chat_log.bbcode_enabled = true
	chat_log.fit_content = true
	chat_log.scroll_active = false
	chat_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chat_log.add_theme_font_size_override("normal_font_size", 13)
	chat_log.position = Vector2(14, 58)
	chat_log.size = Vector2(380, 10)
	chat_log.custom_minimum_size = Vector2(380, 0)
	hud.add_child(chat_log)

	# painel da Bolsa
	market_panel = PanelContainer.new()
	market_panel.add_theme_stylebox_override("panel", _style(Color(0.04, 0.05, 0.11, 0.95), Color(GREEN, 0.6)))
	market_panel.anchor_left = 1.0
	market_panel.anchor_right = 1.0
	market_panel.offset_left = -560.0
	market_panel.offset_right = -12.0
	market_panel.offset_top = 60.0
	market_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	market_panel.visible = false
	hud.add_child(market_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	market_panel.add_child(vb)
	var head := HBoxContainer.new()
	vb.add_child(head)
	var title := _label("BOLSA NEXO  —  mercado entre jogadores", GREEN)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := Button.new()
	close.text = "X"
	close.pressed.connect(func(): _toggle_market(false))
	head.add_child(close)
	var sub := _label("Preços simulados: sobem quando compram, caem quando vendem. Taxa de 3% na venda.",
		Color(0.6, 0.65, 0.75), 12)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(sub)

	for i in market.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vb.add_child(row)
		var n := _label(market[i]["name"])
		n.custom_minimum_size.x = 140
		row.add_child(n)
		var p := _label("", GOLD)
		p.custom_minimum_size.x = 82
		p.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(p)
		var c := _label("")
		c.custom_minimum_size.x = 64
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(c)
		var o := _label("", Color(0.7, 0.75, 0.85))
		o.custom_minimum_size.x = 36
		o.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(o)
		var buy := Button.new()
		buy.text = "Comprar"
		buy.pressed.connect(_buy.bind(i))
		row.add_child(buy)
		var sell := Button.new()
		sell.text = "Vender"
		sell.pressed.connect(_sell.bind(i))
		row.add_child(sell)
		market_rows.append({"price": p, "change": c, "owned": o})

	# dica + chat embaixo
	var hint := _label("Toque no chão pra andar  •  Toque nos objetos  •  Mesa verde = Bolsa",
		Color(0.55, 0.6, 0.7), 12)
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = 14.0
	hint.offset_top = -92.0
	hint.offset_bottom = -72.0
	hud.add_child(hint)

	var chat := HBoxContainer.new()
	chat.anchor_left = 0.5
	chat.anchor_right = 0.5
	chat.anchor_top = 1.0
	chat.anchor_bottom = 1.0
	chat.offset_left = -260.0
	chat.offset_right = 300.0
	chat.offset_top = -62.0
	chat.offset_bottom = -16.0
	hud.add_child(chat)
	chat_input = LineEdit.new()
	chat_input.placeholder_text = "Fale algo... (escreva \"eco\" pra chamar sua IA)"
	chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_input.text_submitted.connect(_on_chat)
	chat.add_child(chat_input)
	var send := Button.new()
	send.text = "Enviar"
	send.pressed.connect(func(): _on_chat(chat_input.text))
	chat.add_child(send)
