# 🎧 Sound Tune Key

🇺🇸 **English** | 🇧🇷 [Português](README.pt-BR.md)

Control the audio of **one specific app** straight from your keyboard.

Pick the app you want to control — Spotify, Google Chrome, Discord or anything else that is playing sound — and use global hotkeys to change its volume, pause it or skip tracks. The rest of your PC's volume stays untouched.

[![Download SoundTuneKey.exe](https://img.shields.io/badge/Download-SoundTuneKey.exe-1DB954?style=for-the-badge&logo=windows)](https://github.com/ppdrada/SoundTuneKey/releases/latest/download/SoundTuneKey.exe)

---

## 💻 Requirements

- Windows 10 or 11
- Nothing to install: it is a single `.exe`.

---

## ⌨️ Hotkeys

| Hotkey | Action |
|---|---|
| `Ctrl + Alt + ↑` | 🔊 Volume up for the selected app |
| `Ctrl + Alt + ↓` | 🔉 Volume down for the selected app |
| `Ctrl + Alt + P` | ⏯️ Play / pause |
| `Ctrl + Alt + →` | ⏭️ Next track |
| `Ctrl + Alt + ←` | ⏪ Restart the current track · press twice within 1 s for ⏮️ previous track |

> ℹ️ Play/pause and track skipping depend on the app exposing media controls to Windows (Spotify and Chrome tabs do). Apps without that support, such as Discord, can only have their volume controlled.

The hotkeys are also listed inside the app, in the window and in the **Atalhos** item of the tray icon.


## 🚀 How to use

1. Click **Download SoundTuneKey.exe** above (or see every version on [Releases](https://github.com/ppdrada/SoundTuneKey/releases)).
2. Open the program.
3. Select the app you want to control from the list.
4. Done! Use the hotkeys above, even while in-game.

The program remembers the last app you picked the next time it opens.

### ⚠️ Windows warning on first run

The `.exe` is not digitally signed yet, so Windows may show **"Windows protected your PC"**. To open it, click **More info** → **Run anyway**. You only need to do this once.

### 🖥️ System tray

Closing or minimizing the window does not quit the program: it stays in the tray icon (next to the clock) and the hotkeys keep working. Right-click the icon for:

- **Abrir** — show the window again
- **Aplicativos** — switch the controlled app without opening the window
- **Atalhos** — show the hotkey list
- **Iniciar com o Windows** — start the program automatically, already in the tray, when the PC boots
- **Sair** — quit the program

## 🛠️ Built with

- **C# / .NET** — native Windows app
- **Windows Core Audio (WASAPI)** — per-app volume control
- **Windows Media Controls (SMTC)** — play/pause, next and previous
- **Win32 `RegisterHotKey`** — global keyboard hotkeys

---

> 🚧 **Work in progress.**
