# Sound Tune Key — Produto

## O problema

Quem joga e ouve música ao mesmo tempo precisa mexer no volume da música (ou pausar, ou pular) sem sair do jogo. O volume geral do sistema não serve: abaixa o jogo junto. Abrir o mixer de volume ou o Spotify tira o foco do jogo.

## O que é

Um programa pequeno que fica rodando escondido (bandeja do Windows / barra de menus do Mac) e controla o áudio de **um app escolhido** — Spotify, Chrome, Discord ou qualquer outro com som — por **atalhos globais de teclado**, que funcionam com qualquer janela na frente, inclusive jogos em tela cheia.

## Para quem

Primeiro para o próprio autor (gamer, Windows e Mac). O código não tem licença (todos os direitos reservados) porque pode virar produto pago um dia.

## O que faz

| | Windows | macOS |
|---|---|---|
| Lista os apps com som, quem está tocando | ✅ | ✅ |
| Volume só do app escolhido (barra + atalhos) | ✅ `Ctrl+Alt+↑/↓` | ✅ `⌘⌥↑/↓` |
| Segurar o atalho de volume repete | ✅ | ✅ |
| Pausar / próxima / anterior | ✅ `Ctrl+Alt+P/→/←` (só do app escolhido) | ✅ `⌃⌥P/→/←` (app escolhido: Spotify, Música, VLC e vídeos do Chrome); F7/F8/F9 do Mac continuam valendo |
| `←` volta ao começo; dois toques em menos de 1 s = música anterior | ✅ | ✅ |
| Mudo do app escolhido (atalho e clique no alto-falante); mexer no volume tira o mudo | ✅ `Ctrl+Alt+M` | ✅ `⌃⌥M` |
| Aviso na tela (volume / mudo) ao usar os atalhos, sem tirar o foco | ✅ | ✅ (aparece até sobre tela cheia) |
| Trocar o app controlado pelo teclado (próximo da lista), com o aviso na tela | ✅ `Ctrl+Alt+A` | ✅ `⌃⌥A` |
| Botões ⏮ ⏯ ⏭ na janela e no topo do menu da bandeja / barra de menus, junto com o tempo e o volume | ✅ | ✅ Spotify, Música, VLC e vídeos do Chrome (apagados nos outros apps) |
| Barra de tempo da música (arrastar para pular), diferente da de volume | ✅ | ✅ Spotify, Música, VLC e vídeos do Chrome |
| Fica escondido (bandeja / barra de menus), fechar só esconde | ✅ | ✅ |
| "Verificar atualizações..." e "Sobre" (versão, autor, GitHub) no menu, com janelinha de cantos arredondados | ✅ | ✅ |
| Atualiza sozinho (baixa, troca e reabre) e avisa versão nova (balão, menu e faixa na janela, uma vez por dia) | ✅ | ✅ (`download/version-mac.txt`; troca o `.app`) |
| Mudo do microfone do Windows (atalho, ícone no rodapé, linha no menu, aviso na tela) | ✅ `Ctrl+Alt+V` | ✅ `⌃⌥V` (microfone padrão do Mac) |
| Lista de atalhos dentro do app | ✅ | ✅ |
| Iniciar com o sistema (abre escondido) | ✅ | ✅ |
| Lembrar o último app | ✅ | ✅ (e o volume de cada app) |
| Download direto pelo README | ✅ `.exe` único | ✅ `.zip` universal (chip Apple e Intel) |

## O que não faz (de propósito)

- **Não mexe no volume geral** do sistema nem no de outros apps.
- **Não separa abas ou atalhos do Chrome**: o atalho do YouTube Music instalado pelo Chrome é o Chrome para o sistema (veja os riscos em `ARCHITECTURE.md`). Quem quiser separar usa outro navegador para ele.
- **Sem assinatura de código paga** (certificado no Windows, conta Apple Developer no Mac): o app é grátis, então o usuário libera o aviso de segurança na primeira vez.
- **Sem instalador**: um `.exe` no Windows, um `.app` dentro de um `.zip` no Mac.

## Roteiro

Cada etapa é pequena, testada pelo usuário e entra por PR (veja `CLAUDE.md`).

**Windows** — pronto, incluindo os botões de mídia e a barra de tempo (PR `feat/media-buttons`) e o mesmo layout, mini player na bandeja e animações do Mac (PR `feat/windows-mini-player`).

**macOS**
1. ✅ Janela listando os apps com som
2. ✅ Volume por app + atalhos `⌘⌥↑/↓`
3. ✅ Caixa de atalhos na janela, README por sistema
4. ✅ Ícone na barra de menus + download universal
5. ✅ Iniciar com o Mac + lembrar o último app e os volumes
6. ✅ Botões ⏮ ⏯ ⏭ e barra de tempo, na janela e no topo do menu da barra
7. ✅ Mídia dos vídeos do Chrome (JavaScript pelo AppleScript), com o botão "Como ligar" para a opção do Chrome
8. Atalhos de mídia `⌃⌥P/→/←` (escritos no PC Windows: falta compilar e testar no Mac)
9. Depois: só o que o usuário pedir.

**Ideias em aberto (não fazer sem perguntar)**

## Identidade visual

- **Ícone** feito pelo usuário: barras de volume crescentes, uma linha embaixo com uma bolinha de "play". Fica em `assets/icon/` (`icon.svg` é a fonte; `.png` e `.ico` derivam dele). Não criar outro.
- **Tema escuro** com as cores do ícone, igual nos dois sistemas:

| Uso | Cor |
|---|---|
| Fundo | `#1C1C1E` |
| Superfície (lista) | `#242427` |
| Elevado | `#2C2C30` |
| Borda / seleção | `#3A3A40` |
| Texto | `#F2F2F2` |
| Texto secundário | `#9A9AA0` |
| Apagado | `#4A4A50` |

- **Janela de tamanho fixo** (411 × 500 de área útil nos dois), só com o botão de fechar. De cima para baixo:
  - Windows: lista de apps (nome, volume), "Controlando: <app>", barra de tempo, botões ⏮ ⏯ ⏭, barra de volume (a lista se atualiza sozinha a cada 5 s), rodapé com "Iniciar com o Windows", "Atalhos" e "Sobre". "Atalhos" e "Sobre" abrem janelinhas sem barra de título e com cantos arredondados (no rodapé e no menu da bandeja). Mesma ordem do Mac e do mini player da bandeja.
  - Mac: lista de apps (nome, tocando/parado, volume), "Controlando: <app>", barra de tempo, botões ⏮ ⏯ ⏭, barra de volume, caixa de atalhos, "Iniciar com o Mac". O volume fica **embaixo** dos botões (pedido do usuário), na mesma ordem da linha do menu da barra. A lista se atualiza sozinha, sem botão.
- **Itens clicáveis** (nos dois): mãozinha do mouse em cima; os botões ⏮ ⏯ ⏭ são só o ícone, mostram um círculo claro ao passar o mouse e encolhem um pouco ao clicar (animados).
- **Barra de volume** desenhada: trilha clara até o volume, apagada depois, bolinha para arrastar. Alto-falante à esquerda e a porcentagem à direita.
- **Barra de tempo**: o mesmo desenho, porém **mais fina** (trilha 4 px, bolinha 12 px; a de volume tem 6 e 18), com o tempo atual à esquerda e a duração à direita (`1:23` … `3:45`). Assim o usuário não confunde as duas. Apagada com `--:--` quando o app não informa o tempo.
- **Ícones de mídia** (⏮ ⏯ ⏭ e o alto-falante) desenhados em código, não com caracteres de fonte: os caracteres saíam pequenos, fora do centro ou coloridos (emoji) no menu.
- **Textos do programa em português, inglês e espanhol** (Windows e Mac; escolha no "Sobre", na primeira vez segue o idioma do sistema). O README principal é em inglês, com o PT-BR e o espanhol ao lado.
