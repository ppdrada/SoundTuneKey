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

Under "Controlando" (Controlling), the window has the track **time bar** (current time on the left, length on the right; drag to jump to another part of the song or video), the **⏮ ⏯ ⏭** buttons, which do the same as the hotkeys, and the 🔈 volume bar. The time bar only works with apps that report the track time to Windows (Spotify and Chrome tabs do).

#### ⚠️ Windows warning on first run

The `.exe` is not digitally signed yet, so Windows may show **"Windows protected your PC"**. To open it, click **More info** → **Run anyway**. You only need to do this once.

#### 🖥️ System tray

Closing or minimizing the window does not quit the program: it stays in the tray icon (next to the clock) and the hotkeys keep working. The program is in Portuguese; right-click the icon for:

- At the top, like Spotify: the **time bar**, the **⏮ ⏯ ⏭** buttons and the **volume** of the selected app; the menu stays open so you can click more than once
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

The program remembers the last app you picked and the volume of each app. The volume only applies while Sound Tune Key is open: when you quit it, every app goes back to its normal volume until you open it again.

The **Iniciar com o Mac** (Start with Mac) checkbox at the bottom of the window opens the program automatically, already in the menu bar, when you log in. Move the app to **Applications** before turning it on.

Under "Controlando" (Controlling), the window has the track **time bar** (current time on the left, length on the right; drag to jump to another part), the **⏮ ⏯ ⏭** buttons and the 🔈 volume bar. ⏮ restarts the current track; press it twice within 1 s for the previous track. The buttons and the time bar work with **Spotify**, **Music** and videos in **Google Chrome**: the first time, macOS asks whether Sound Tune Key may control them, just allow it. With other apps they are greyed out.

> ℹ️ **Chrome:** turn on, once in each Chrome profile, **Ver → Desenvolvedor → Permitir o JavaScript do Eventos da Apple** (View → Developer → Allow JavaScript from Apple Events) in the Mac menu bar while Chrome is in front. Until then, Sound Tune Key shows a warning with a **Como ligar** (How to turn it on) button that lists the steps and brings Chrome to the front. Chrome's volume works without it. In Chrome, ⏭ and the double ⏮ switch videos on YouTube.

#### ⚠️ macOS warning on first run

The app is not notarized by Apple, so the first time macOS says it could not verify it. Click **Done**, then go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway**. You only need to do this once.

#### 🖥️ Menu bar

Closing the window does not quit the program: it stays in the menu bar icon (next to Wi-Fi) and the hotkeys keep working. To move the icon, hold **⌘** and drag it. The program is in Portuguese; click the icon for:

- At the top, like Spotify: the **time bar**, the **⏮ ⏯ ⏭** buttons and the **volume** of the selected app; the menu stays open so you can click more than once
- **Abrir** (Open) — show the window again
- **Aplicativos** (Apps) — switch the controlled app without opening the window
- **Atalhos** (Hotkeys) — show the hotkey list
- **Iniciar com o Mac** (Start with Mac) — start the program automatically, already in the menu bar, when you log in
- **Sair** (Quit) — quit the program

To build it from source instead, run `mac/build-app.sh` (needs the Xcode Command Line Tools: `xcode-select --install`).

---

## 🛠️ Built with

### Windows

- **C# / .NET** — native Windows app
- **Windows Core Audio (WASAPI)** — per-app volume control
- **Windows Media Controls (SMTC)** — play/pause, next, previous and the track time bar
- **Win32 `RegisterHotKey`** — global keyboard hotkeys

### macOS

- **Swift / SwiftUI** — native Mac app
- **Core Audio process taps** — per-app volume control
- **AppleScript** — play/pause, next, previous and the time bar for Spotify and Music, and for Chrome videos through JavaScript
- **Carbon `RegisterEventHotKey`** — global keyboard hotkeys
