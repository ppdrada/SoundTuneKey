# <img src="assets/icon/icon.png" alt="Sound Tune Key logo" width="36"> Sound Tune Key

🇺🇸 **English** | 🇧🇷 [Português](README.pt-BR.md)

Control the audio of **one specific app** straight from your keyboard.

Pick the app you want to control — Spotify, Google Chrome, Discord or anything else that is playing sound — and use global hotkeys to change its volume, pause it or skip tracks. The rest of your computer's volume stays untouched.

[![Download for Windows](https://img.shields.io/badge/Windows-Download_.exe-1DB954?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/ppdrada/SoundTuneKey/raw/main/download/SoundTuneKey.exe) [![Download for macOS](https://img.shields.io/badge/macOS-Download_.zip-1DB954?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/ppdrada/SoundTuneKey/raw/main/download/SoundTuneKey-mac.zip)

---

## 💻 Requirements

### Windows

- Windows 10 or 11
- Nothing to install: it is a single `.exe`.

### macOS

- macOS 14.2 or later, on Apple chip or Intel Macs
- Nothing to install: unzip and open.

---

## ⌨️ Hotkeys

### Windows

| Hotkey | Action |
|---|---|
| `Ctrl + Alt + ↑` | 🔊 Volume up for the selected app |
| `Ctrl + Alt + ↓` | 🔉 Volume down for the selected app |
| `Ctrl + Alt + P` | ⏯️ Play / pause |
| `Ctrl + Alt + →` | ⏭️ Next track |
| `Ctrl + Alt + ←` | ⏪ Restart the current track · press twice within 1 s for ⏮️ previous track |

> ℹ️ Play/pause and track skipping depend on the app exposing media controls to Windows (Spotify and Chrome tabs do). Apps without that support, such as Discord, can only have their volume controlled.

The hotkeys are also listed inside the app, in the window and in the **Atalhos** (Hotkeys) item of the tray icon.

### macOS

| Hotkey | Action |
|---|---|
| `⌘ + ⌥ + ↑` | 🔊 Volume up for the selected app (hold to repeat) |
| `⌘ + ⌥ + ↓` | 🔉 Volume down for the selected app (hold to repeat) |
| `F8` | ⏯️ Play / pause |
| `F9` | ⏭️ Next track |
| `F7` | ⏮️ Previous track |

> ℹ️ Play/pause and track skipping use the Mac keyboard's own media keys, which control the app that is playing right now. The hotkeys are also listed inside the app, at the bottom of the window.

---

## 🚀 How to use

### Windows

1. Click **Windows · Download .exe** above.
2. Open the program.
3. Select the app you want to control from the list.
4. Done! Use the hotkeys above, even while in-game.

The program remembers the last app you picked the next time it opens.

#### ⚠️ Windows warning on first run

The `.exe` is not digitally signed yet, so Windows may show **"Windows protected your PC"**. To open it, click **More info** → **Run anyway**. You only need to do this once.

#### 🖥️ System tray

Closing or minimizing the window does not quit the program: it stays in the tray icon (next to the clock) and the hotkeys keep working. The program is in Portuguese; right-click the icon for:

- **Abrir** (Open) — show the window again
- **Aplicativos** (Apps) — switch the controlled app without opening the window
- **Atalhos** (Hotkeys) — show the hotkey list
- **Iniciar com o Windows** (Start with Windows) — start the program automatically, already in the tray, when the PC boots
- **Sair** (Quit) — quit the program

### macOS

1. Click **macOS · Download .zip** above and open the `.zip` to unzip it.
2. Move `SoundTuneKey.app` to the **Applications** folder and open it.
3. Select the app you want to control from the list.
4. The first time you change a volume, macOS asks for **System Audio Recording** permission: allow it. That is how Sound Tune Key changes the volume of one app only.

The volume only applies while Sound Tune Key is open: when you quit it, every app goes back to its normal volume.

#### ⚠️ macOS warning on first run

The app is not notarized by Apple, so the first time macOS says it could not verify it. Click **Done**, then go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway**. You only need to do this once.

#### 🖥️ Menu bar

Closing the window does not quit the program: it stays in the menu bar icon (next to Wi-Fi) and the hotkeys keep working. To move the icon, hold **⌘** and drag it. The program is in Portuguese; click the icon for:

- **Abrir** (Open) — show the window again
- **Aplicativos** (Apps) — switch the controlled app without opening the window
- **Atalhos** (Hotkeys) — show the hotkey list
- **Sair** (Quit) — quit the program

To build it from source instead, run `mac/build-app.sh` (needs the Xcode Command Line Tools: `xcode-select --install`).

---

## 🛠️ Built with

### Windows

- **C# / .NET** — native Windows app
- **Windows Core Audio (WASAPI)** — per-app volume control
- **Windows Media Controls (SMTC)** — play/pause, next and previous
- **Win32 `RegisterHotKey`** — global keyboard hotkeys

### macOS

- **Swift / SwiftUI** — native Mac app
- **Core Audio process taps** — per-app volume control
- **Carbon `RegisterEventHotKey`** — global keyboard hotkeys
