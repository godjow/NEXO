# NEXO: protótipo (fase 1)

O Habbo era um **hotel** dos anos 2000. O NEXO é uma **cidade vertical dos anos 2030**: cada jogador tem um loft num prédio da cidade, conta com uma IA que o acompanha e participa de uma economia de verdade entre os jogadores.

## O que muda em relação ao Habbo

| Habbo | NEXO |
|---|---|
| Hotel com quartos | Cidade vertical com lofts e distritos (Neon, Verde, Porto...) |
| Mobis com preço fixo | **Bolsa NEXO**: o preço de cada item muda com a oferta e a procura, tem histórico e cobra taxa na venda |
| Nenhum assistente | **Eco**, uma IA companheira que dá dicas, ajuda a negociar e, no futuro, cuida da sua loja enquanto você está offline |
| Só a empresa cria os itens | **Economia de criadores**: o jogador cria um item e ganha comissão cada vez que ele é revendido |
| Raros sem rastreio | **Edições limitadas** com número de série e histórico de donos, guardados no seu próprio servidor, sem precisar de blockchain |
| Janela de enfeite | **O mundo lá fora tem vida**: drones, eventos ao vivo e arte gerada por IA nas paredes |
| Roupas de pixel | Visual de agora: óculos de realidade aumentada, tênis com LED e casa inteligente |

## Como abrir

1. Baixe o **Godot 4.3 ou mais novo** em godotengine.org (é grátis).
2. Descompacte este zip.
3. No Godot, clique em **Importar**, escolha o arquivo `project.godot` e depois clique em **Importar e Editar**.
4. Aperte **F5** para jogar.

Todo o visual é desenhado por código, então o projeto não precisa de nenhuma imagem.

## Controles

- Clique ou toque no chão para andar (o caminho desvia dos móveis).
- Clique num objeto e a Eco explica o que ele faz.
- A **mesa verde**, ou o botão "Bolsa NEXO", abre o mercado, onde você compra e vende itens e acompanha o patrimônio.
- No chat, qualquer mensagem com **"eco"** recebe resposta da IA. Experimente "eco, como tá a bolsa?".

## Arquivos

- `scripts/main.gd`: monta a cena, cuida do toque e do chat, da Bolsa e das telas
- `scripts/room.gd`: piso, paredes, janela com a cidade, quadro de IA e cálculo dos caminhos
- `scripts/avatar.gd`: o jogador
- `scripts/eco.gd`: a IA companheira (por enquanto com respostas prontas)
- `scripts/furniture.gd`: os móveis inteligentes (sofá, estação de trade, holo-globo, planta e servidor)
- `scripts/speech_bubble.gd`: os balões de fala

## O que ainda é simulado

- A Bolsa roda só no seu computador e os preços variam ao acaso.
- A Eco responde por palavras-chave e ainda não é uma IA de verdade.
- O NX$ é só um número local, sem conta nem servidor.

## Próximas fases

2. **Multiplayer**: vários jogadores no mesmo loft, com chat (usando Nakama ou um servidor próprio em Node.js).
3. **Contas, inventário e Bolsa real**: os preços passam a ser calculados **no servidor**, nunca no jogo.
4. **Pagamentos**: Pix e cartão pelo Mercado Pago, e cripto por uma empresa de pagamento em cripto. As moedas só entram na conta quando a empresa de pagamento confirma o pagamento ao servidor.
5. **IA de verdade na Eco**: o servidor conversa com o modelo de IA, e a chave da API fica só lá.
6. **Moderação e lançamento.**

## Regras de ouro

- **Nunca confie no jogo do jogador.** Saldo, preços e itens moram sempre no servidor.
- **Sem loot boxes** (caixas de prêmio aleatório pagas). O ECA Digital proíbe esse tipo de caixa em jogos que menores podem acessar, e também limita o chat com menores.
- **O NX$ não deve voltar a virar dinheiro.** Se o jogador puder sacar NX$ em reais, a parte legal fica muito mais complicada. Vale conversar com um advogado antes.
