# 🎧 Sound Tune Key

🇺🇸 **English** | 🇧🇷 [Português](README.pt-BR.md)

Control the audio of **one specific app** straight from your keyboard.

Pick the app you want to control — Spotify, Google Chrome, Discord or anything else that is playing sound — and use global hotkeys to change its volume, pause it or skip tracks. The rest of your PC's volume stays untouched.

---

## 💻 Requirements

- Windows 10 or 11

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


## 🚀 How to use

1. Download `SoundTuneKey.exe` from the [Releases](https://github.com/ppdrada/SoundTuneKey/releases) page.
2. Open the program.
3. Select the app you want to control from the list.
4. Done! Use the hotkeys above, even while in-game.

To quit, right-click the Sound Tune Key icon in the Windows system tray and choose **Exit**.

## 🛠️ Built with

- **C# / .NET** — native Windows app
- **Windows Core Audio (WASAPI)** — per-app volume control
- **Windows Media Controls (SMTC)** — play/pause, next and previous
- **Win32 `RegisterHotKey`** — global keyboard hotkeys

---

> 🚧 **Work in progress.**
