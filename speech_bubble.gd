extends PanelContainer
## Balão de fala que flutua acima de um personagem.

var label: Label
var time_left := 0.0
var offset_y := -90.0
var align := 0.0  # 0 = centralizado, 1 = cresce pra direita, -1 = cresce pra esquerda
var style: StyleBoxFlat


func _init() -> void:
	style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.13, 0.94)
	style.border_color = Color(0.2, 0.9, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	add_theme_stylebox_override("panel", style)

	label = Label.new()
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 60
	visible = false


func set_accent(c: Color) -> void:
	style.border_color = c


func say(text: String, secs: float = 4.5) -> void:
	if text.length() > 32:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(240, 0)
	else:
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.custom_minimum_size = Vector2.ZERO
	label.text = text
	time_left = secs
	visible = true
	reset_size()


func _process(delta: float) -> void:
	if not visible:
		return
	time_left -= delta
	if time_left <= 0.0:
		visible = false
	var x := -size.x * 0.5
	if align > 0.0:
		x = -16.0
	elif align < 0.0:
		x = -size.x + 16.0
	position = Vector2(x, offset_y - size.y)
