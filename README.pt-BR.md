# 🎧 Sound Tune Key

🇺🇸 [English](README.md) | 🇧🇷 **Português**

Controle o áudio de **um aplicativo específico** direto pelo teclado.

Escolha o app que você quer controlar — Spotify, Google Chrome, Discord ou qualquer outro que esteja tocando som — e use atalhos globais para ajustar o volume, pausar ou trocar de música. O volume do resto do PC não é alterado.

---

## 💻 Requisitos

- Windows 10 ou 11

---

## ⌨️ Atalhos

| Atalho | Função |
|---|---|
| `Ctrl + Alt + ↑` | 🔊 Aumenta o volume do app selecionado |
| `Ctrl + Alt + ↓` | 🔉 Diminui o volume do app selecionado |
| `Ctrl + Alt + P` | ⏯️ Pausar / continuar |
| `Ctrl + Alt + →` | ⏭️ Próxima música |
| `Ctrl + Alt + ←` | ⏮️ Música anterior |

> ℹ️ Pausar e trocar de música dependem de o app expor controles de mídia ao Windows (Spotify e abas do Chrome expõem). Apps sem esse suporte, como o Discord, podem ser controlados apenas no volume.


## 🚀 Como usar

1. Baixe o `SoundTuneKey.exe` na página de [Releases](https://github.com/ppdrada/SoundTuneKey/releases).
2. Abra o programa.
3. Selecione na lista o aplicativo que você quer controlar.
4. Pronto! Use os atalhos acima, inclusive dentro do jogo.

Para encerrar, clique com o botão direito no ícone do Sound Tune Key na bandeja do Windows e escolha **Sair**.

## 🛠️ Tecnologias

- **C# / .NET** — aplicativo nativo para Windows
- **Windows Core Audio (WASAPI)** — controle de volume por aplicativo
- **Windows Media Controls (SMTC)** — pausar, próxima e anterior
- **Win32 `RegisterHotKey`** — atalhos globais de teclado

---

> 🚧 **Em desenvolvimento.**
