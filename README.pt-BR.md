# 🎧 Sound Tune Key

🇺🇸 [English](README.md) | 🇧🇷 **Português**

Controle o áudio de **um aplicativo específico** direto pelo teclado.

Escolha o app que você quer controlar — Spotify, Google Chrome, Discord ou qualquer outro que esteja tocando som — e use atalhos globais para ajustar o volume, pausar ou trocar de música. O volume do resto do PC não é alterado.

[![Baixar SoundTuneKey.exe](https://img.shields.io/badge/Baixar-SoundTuneKey.exe-1DB954?style=for-the-badge&logo=windows)](https://github.com/ppdrada/SoundTuneKey/raw/main/download/SoundTuneKey.exe)

---

## 💻 Requisitos

- Windows 10 ou 11
- Não precisa instalar nada: é um único `.exe`.

---

## ⌨️ Atalhos

| Atalho | Função |
|---|---|
| `Ctrl + Alt + ↑` | 🔊 Aumenta o volume do app selecionado |
| `Ctrl + Alt + ↓` | 🔉 Diminui o volume do app selecionado |
| `Ctrl + Alt + P` | ⏯️ Pausar / continuar |
| `Ctrl + Alt + →` | ⏭️ Próxima música |
| `Ctrl + Alt + ←` | ⏪ Volta ao começo da música · aperte duas vezes em menos de 1 s para ⏮️ música anterior |

> ℹ️ Pausar e trocar de música dependem de o app expor controles de mídia ao Windows (Spotify e abas do Chrome expõem). Apps sem esse suporte, como o Discord, podem ser controlados apenas no volume.

Os atalhos também aparecem dentro do programa, na janela e no item **Atalhos** do ícone da bandeja.


## 🚀 Como usar

1. Clique em **Baixar SoundTuneKey.exe** acima.
2. Abra o programa.
3. Selecione na lista o aplicativo que você quer controlar.
4. Pronto! Use os atalhos acima, inclusive dentro do jogo.

O programa lembra o último app escolhido da próxima vez que for aberto.

### ⚠️ Aviso do Windows na primeira vez

O `.exe` ainda não tem assinatura digital, então o Windows pode mostrar **"O Windows protegeu o computador"**. Para abrir, clique em **Mais informações** → **Executar assim mesmo**. Isso só é preciso na primeira vez.

### 🖥️ Bandeja do Windows

Fechar ou minimizar a janela não encerra o programa: ele continua no ícone da bandeja (perto do relógio) e os atalhos seguem funcionando. Clique com o botão direito no ícone para:

- **Abrir** — mostra a janela de novo
- **Aplicativos** — troca o app controlado sem abrir a janela
- **Atalhos** — mostra a lista de atalhos
- **Iniciar com o Windows** — abre o programa sozinho, já na bandeja, quando o PC liga
- **Sair** — encerra o programa

## 🛠️ Tecnologias

- **C# / .NET** — aplicativo nativo para Windows
- **Windows Core Audio (WASAPI)** — controle de volume por aplicativo
- **Windows Media Controls (SMTC)** — pausar, próxima e anterior
- **Win32 `RegisterHotKey`** — atalhos globais de teclado
