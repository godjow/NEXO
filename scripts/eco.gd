extends Node2D
## Eco — IA companheira em forma de drone.
## No protótipo as respostas são roteirizadas. Numa fase futura, o SERVIDOR chama um
## modelo de IA de verdade (a chave da API nunca fica dentro do jogo).

const Bubble = preload("res://scripts/speech_bubble.gd")
const COLOR := Color(1.0, 0.4, 0.9)
const TIPS := [
	"Itens com número de série baixo costumam valer mais na Bolsa.",
	"Seu loft recebe mais visitas se tiver algo interativo. Que tal um holo-globo?",
	"Dica de trader: nunca coloque todo seu NX$ num item só.",
	"Em breve você vai poder criar seus próprios móveis e ganhar comissão em cada revenda.",
	"Quando você estiver offline, eu vou poder cuidar da sua lojinha. Na fase 3, prometo.",
	"Olha pela janela: os drones de entrega não param nunca nessa cidade.",
	"O quadro da parede é arte gerada por IA. Ele nunca repete a mesma imagem.",
]

var follow  # avatar que a Eco acompanha
var t := 0.0
var hover_h := 72.0
var bubble


func _ready() -> void:
	bubble = Bubble.new()
	bubble.offset_y = -hover_h - 24.0
	bubble.set_accent(COLOR)
	add_child(bubble)
	if follow:
		position = follow.position + Vector2(-36, 4)


func _process(delta: float) -> void:
	t += delta
	if follow:
		var side: float = -follow.facing
		var target: Vector2 = follow.position + Vector2(36.0 * side, 4.0)
		position = position.lerp(target, clampf(delta * 3.0, 0.0, 1.0))
		bubble.align = 1.0 if position.x >= follow.position.x else -1.0
	queue_redraw()


func _draw() -> void:
	var c := Vector2(0, -hover_h + sin(t * 3.0) * 5.0)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 9.0, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for i in 3:
		draw_circle(c, 20.0 - i * 4.0, Color(COLOR, 0.06 + i * 0.05))
	draw_circle(c, 10.0, Color(0.1, 0.05, 0.2))
	draw_arc(c, 13.0, t * 2.0, t * 2.0 + PI * 1.3, 24, COLOR, 2.0)

	var dir := 1.0
	if follow:
		dir = follow.facing
	draw_circle(c + Vector2(3.0 * dir, -1.0), 3.5, Color(0.4, 1.0, 1.0))

	# hélice girando
	var half := 14.0 * absf(sin(t * 25.0))
	draw_line(c + Vector2(0, -10), c + Vector2(0, -15), Color(1, 1, 1, 0.5), 1.0)
	draw_line(c + Vector2(-half, -15), c + Vector2(half, -15), Color(1, 1, 1, 0.6), 2.0)


func say(text: String) -> void:
	bubble.say(text, 5.5)


func random_tip() -> String:
	return TIPS[randi() % TIPS.size()]


func reply(msg: String, market: Array) -> String:
	var m := msg.to_lower()
	if _has(m, ["bolsa", "preço", "preco", "trade", "investir", "comprar", "vender", "mercado"]):
		var best: Dictionary = market[0]
		var worst: Dictionary = market[0]
		for it in market:
			if it["change"] > best["change"]:
				best = it
			if it["change"] < worst["change"]:
				worst = it
		return "Agora quem mais sobe é %s (%+.1f%%) e quem mais cai é %s (%+.1f%%). Não é conselho financeiro, hein!" % [
			best["name"], best["change"] * 100.0, worst["name"], worst["change"] * 100.0]
	if _has(m, ["quem é", "quem e", "o que você", "o que voce"]):
		return "Sou a Eco, sua IA de bolso. Te ajudo a decorar, negociar e conhecer a cidade."
	if _has(m, ["decor", "móve", "move", "loft", "casa"]):
		return "Coloca algo interativo no centro do loft. Objetos interativos atraem visitas, e visitas dão reputação."
	if _has(m, ["dinheiro", "ganhar", "grana", "lucro"]):
		return "Três jeitos: revender itens na Bolsa, criar itens próprios ou alugar seu loft pra eventos."
	if _has(m, ["oi", "olá", "ola", "eae", "salve", "bom dia", "boa noite"]):
		return "Oi! Tô aqui. Me pergunta sobre a Bolsa, decoração ou como ganhar NX$."
	return random_tip()


func _has(m: String, words: Array) -> bool:
	for w in words:
		if m.contains(w):
			return true
	return false
