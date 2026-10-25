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
| Pausar / próxima / anterior | ✅ `Ctrl+Alt+P/→/←` (só do app escolhido) | Teclas de mídia do próprio Mac (F7/F8/F9), que controlam o app que está tocando |
| `←` volta ao começo; dois toques em menos de 1 s = música anterior | ✅ | — (F7 do Mac) |
| Fica escondido (bandeja / barra de menus), fechar só esconde | ✅ | ✅ |
| Lista de atalhos dentro do app | ✅ | ✅ |
| Iniciar com o sistema (abre escondido) | ✅ | ✅ |
| Lembrar o último app | ✅ | ✅ (e o volume de cada app) |
| Download direto pelo README | ✅ `.exe` único | ✅ `.zip` universal (chip Apple e Intel) |

## O que não faz (de propósito)

- **Não mexe no volume geral** do sistema nem no de outros apps.
- **Não separa abas ou atalhos do Chrome**: o atalho do YouTube Music instalado pelo Chrome é o Chrome para o sistema (veja os riscos em `ARCHITECTURE.md`). Quem quiser separar usa outro navegador para ele.
- **Sem atalhos de mídia próprios no Mac**: o teclado do Mac já tem as teclas de mídia. Isso foi escolha do usuário.
- **Sem assinatura de código paga** (certificado no Windows, conta Apple Developer no Mac): o app é grátis, então o usuário libera o aviso de segurança na primeira vez.
- **Sem instalador**: um `.exe` no Windows, um `.app` dentro de um `.zip` no Mac.

## Roteiro

Cada etapa é pequena, testada pelo usuário e entra por PR (veja `CLAUDE.md`).

**Windows** — pronto.

**macOS**
1. ✅ Janela listando os apps com som
2. ✅ Volume por app + atalhos `⌘⌥↑/↓`
3. ✅ Caixa de atalhos na janela, README por sistema
4. ✅ Ícone na barra de menus + download universal
5. ✅ Iniciar com o Mac + lembrar o último app e os volumes
6. Depois: só o que o usuário pedir.

**Ideias em aberto (não fazer sem perguntar)**
- Aviso na tela (OSD) ao apertar um atalho: perguntado várias vezes no Windows, nunca respondido.
- Programa em inglês além de português.

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

- **Janela de tamanho fixo** (411 × 458 de área útil), só com o botão de fechar. De cima para baixo: lista de apps (nome, tocando/parado, volume), "Controlando: <app>" com a barra de volume, caixa de atalhos.
- **Barra de volume** desenhada: trilha clara até o volume, apagada depois, bolinha para arrastar.
- **Textos do programa em português.** O README principal é em inglês, com o PT-BR ao lado.
