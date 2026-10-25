# <img src="assets/icon/icon.png" alt="Logo do Sound Tune Key" width="36"> Sound Tune Key

🇺🇸 [English](README.md) | 🇧🇷 **Português**

Controle o áudio de **um aplicativo específico** direto pelo teclado.

Escolha o app que você quer controlar — Spotify, Google Chrome, Discord ou qualquer outro que esteja tocando som — e use atalhos globais para ajustar o volume, pausar ou trocar de música. O volume do resto do computador não é alterado.

[![Baixar para Windows](https://img.shields.io/badge/Windows-Baixar_.exe-1DB954?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/ppdrada/SoundTuneKey/raw/main/download/SoundTuneKey.exe) [![Baixar para macOS](https://img.shields.io/badge/macOS-Baixar_.zip-1DB954?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/ppdrada/SoundTuneKey/raw/main/download/SoundTuneKey-mac.zip)

---

## 💻 Requisitos

### Windows

- Windows 10 ou 11
- Não precisa instalar nada: é um único `.exe`.

### macOS

- macOS 14.2 ou mais novo, em Macs com chip Apple ou Intel
- Não precisa instalar nada: é só descompactar e abrir.

---

## ⌨️ Atalhos

### Windows

| Atalho | Função |
|---|---|
| `Ctrl + Alt + ↑` | 🔊 Aumenta o volume do app selecionado |
| `Ctrl + Alt + ↓` | 🔉 Diminui o volume do app selecionado |
| `Ctrl + Alt + P` | ⏯️ Pausar / continuar |
| `Ctrl + Alt + →` | ⏭️ Próxima música |
| `Ctrl + Alt + ←` | ⏪ Volta ao começo da música · aperte duas vezes em menos de 1 s para ⏮️ música anterior |

> ℹ️ Pausar e trocar de música dependem de o app expor controles de mídia ao Windows (Spotify e abas do Chrome expõem). Apps sem esse suporte, como o Discord, podem ser controlados apenas no volume.

Os atalhos também aparecem dentro do programa, na janela e no item **Atalhos** do ícone da bandeja.

### macOS

| Atalho | Função |
|---|---|
| `⌘ + ⌥ + ↑` | 🔊 Aumenta o volume do app selecionado (segurar repete) |
| `⌘ + ⌥ + ↓` | 🔉 Diminui o volume do app selecionado (segurar repete) |
| `F8` | ⏯️ Pausar / continuar |
| `F9` | ⏭️ Próxima música |
| `F7` | ⏮️ Música anterior |

> ℹ️ Pausar e trocar de música usam as teclas de mídia do próprio teclado do Mac, que controlam o app que está tocando agora. Os atalhos também aparecem dentro do programa, embaixo da janela.

---

## 🚀 Como usar

### Windows

1. Clique em **Windows · Baixar .exe** acima.
2. Abra o programa.
3. Selecione na lista o aplicativo que você quer controlar.
4. Pronto! Use os atalhos acima, inclusive dentro do jogo.

O programa lembra o último app escolhido da próxima vez que for aberto.

Embaixo de "Controlando", a janela tem a **barra de tempo** da música (tempo atual à esquerda, duração à direita; arraste para ir para outro trecho da música ou do vídeo), os botões **⏮ ⏯ ⏭**, que fazem o mesmo que os atalhos, e a barra de volume 🔈. A barra de tempo só funciona com apps que informam o tempo da música ao Windows (Spotify e abas do Chrome informam).

#### ⚠️ Aviso do Windows na primeira vez

O `.exe` ainda não tem assinatura digital, então o Windows pode mostrar **"O Windows protegeu o computador"**. Para abrir, clique em **Mais informações** → **Executar assim mesmo**. Isso só é preciso na primeira vez.

#### 🖥️ Bandeja do Windows

Fechar ou minimizar a janela não encerra o programa: ele continua no ícone da bandeja (perto do relógio) e os atalhos seguem funcionando. Clique com o botão direito no ícone para:

- No topo, como no Spotify: a **barra de tempo**, os botões **⏮ ⏯ ⏭** e o **volume** do app escolhido; o menu fica aberto para clicar mais de uma vez
- **Abrir** — mostra a janela de novo
- **Aplicativos** — troca o app controlado sem abrir a janela
- **Atalhos** — mostra a lista de atalhos
- **Iniciar com o Windows** — abre o programa sozinho, já na bandeja, quando o PC liga
- **Sair** — encerra o programa

### macOS

1. Clique em **macOS · Baixar .zip** acima e abra o `.zip` para descompactar.
2. Mova o `SoundTuneKey.app` para a pasta **Aplicativos** e abra.
3. Selecione na lista o aplicativo que você quer controlar.
4. Na primeira vez que você mudar um volume, o macOS pede a permissão de **Gravação de áudio do sistema**: aceite. É assim que o Sound Tune Key muda o volume de um app só.

O programa lembra o último app escolhido e o volume de cada app. O volume vale enquanto o Sound Tune Key estiver aberto: ao fechá-lo, os apps voltam ao volume normal até você abrir de novo.

A caixinha **Iniciar com o Mac**, embaixo da janela, abre o programa sozinho, já na barra de menus, quando você entra no Mac. Mova o app para **Aplicativos** antes de ligar.

Embaixo de "Controlando", a janela tem a **barra de tempo** da música (tempo atual à esquerda, duração à direita; arraste para ir para outro trecho), os botões **⏮ ⏯ ⏭** e a barra de volume 🔈. O ⏮ volta ao começo da música; dois toques em menos de 1 s vão para a música anterior. Os botões e a barra de tempo funcionam com o **Spotify** e o **Música**: na primeira vez, o macOS pergunta se o Sound Tune Key pode controlá-los, e é só aceitar. Com outros apps, como o Chrome, eles ficam apagados.

#### ⚠️ Aviso do macOS na primeira vez

O app não é autenticado pela Apple, então na primeira vez o macOS diz que não conseguiu verificá-lo. Clique em **OK**, vá em **Ajustes do Sistema → Privacidade e Segurança**, role até o fim e clique em **Abrir Mesmo Assim**. Isso só é preciso na primeira vez.

#### 🖥️ Barra de menus

Fechar a janela não encerra o programa: ele continua no ícone da barra de menus (perto do Wi-Fi) e os atalhos seguem funcionando. Para mudar o ícone de lugar, segure **⌘** e arraste. Clique no ícone para:

- No topo, como no Spotify: a **barra de tempo**, os botões **⏮ ⏯ ⏭** e o **volume** do app escolhido; o menu fica aberto para clicar mais de uma vez
- **Abrir** — mostra a janela de novo
- **Aplicativos** — troca o app controlado sem abrir a janela
- **Atalhos** — mostra a lista de atalhos
- **Iniciar com o Mac** — abre o programa sozinho, já na barra de menus, quando você entra no Mac
- **Sair** — encerra o programa

Para compilar a partir do código, rode `mac/build-app.sh` (precisa das ferramentas de linha de comando do Xcode: `xcode-select --install`).

---

## 🛠️ Tecnologias

### Windows

- **C# / .NET** — aplicativo nativo para Windows
- **Windows Core Audio (WASAPI)** — controle de volume por aplicativo
- **Windows Media Controls (SMTC)** — pausar, próxima, anterior e a barra de tempo da música
- **Win32 `RegisterHotKey`** — atalhos globais de teclado

### macOS

- **Swift / SwiftUI** — aplicativo nativo para Mac
- **Core Audio process taps** — controle de volume por aplicativo
- **AppleScript** — pausar, próxima, anterior e a barra de tempo no Spotify e no Música
- **Carbon `RegisterEventHotKey`** — atalhos globais de teclado
