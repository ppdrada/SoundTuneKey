# Sound Tune Key — Arquitetura

Dois programas nativos e independentes no mesmo repositório. Não há código compartilhado: cada sistema tem APIs de áudio completamente diferentes.

```
src/SoundTuneKey/   Windows — C# / .NET 10 / WinForms
mac/                macOS   — Swift / AppKit + SwiftUI (SwiftPM, sem projeto Xcode)
assets/icon/        ícone do usuário (svg é a fonte), usado pelos dois
download/           binários distribuídos: SoundTuneKey.exe e SoundTuneKey-mac.zip
docs/               este arquivo e o PRD
```

## Windows (`src/SoundTuneKey/`)

| Arquivo | Papel |
|---|---|
| `AudioApps.cs` | Lista as sessões de áudio do dispositivo de saída padrão (NAudio / WASAPI) e junta as do mesmo processo numa linha (o Chrome tem várias). `SetVolume` muda o volume de todas as sessões do processo. |
| `MediaControls.cs` | Play/pause, próxima, anterior e voltar ao começo pelos controles de mídia do Windows (SMTC), casando a sessão de mídia (`SourceAppUserModelId`) com o nome do processo. |
| `GlobalHotkeys.cs` | `RegisterHotKey` numa janela invisível; avisa se outro programa já usa o atalho. |
| `MainForm.cs` | Janela, lista, barra, bandeja e menu, toque duplo no `←`, abertura escondida com `--tray`. O app escolhido fica no campo `_current`, não na lista. |
| `VolumeBar.cs` / `Theme.cs` | Barra desenhada e tema escuro (título escuro via DWM, ListView e menus desenhados). |
| `WindowsStartup.cs` | "Iniciar com o Windows": chave em `HKCU\...\Run` com `--tray`. |
| `AppSettings.cs` | Último app em `%AppData%\SoundTuneKey\settings.json`. |

**Volume por app:** nativo do Windows (`ISimpleAudioVolume` de cada sessão). O volume fica gravado pelo próprio Windows, mesmo com o Sound Tune Key fechado.

**Compilar e distribuir:**
- Debug: `dotnet run --project src/SoundTuneKey` (sem apphost, veja os riscos).
- Release: `dotnet publish src/SoundTuneKey -c Release -o publish`, que gera um `.exe` único, self-contained, win-x64 (~56 MB). Copiar para `download/SoundTuneKey.exe`.
- `.github/workflows/release.yml` gera uma Release no GitHub ao enviar uma tag `v*`. Nunca foi usado: o usuário prefere o `.exe` em `download/` e não quer a página de Releases no README.

## macOS (`mac/`)

| Arquivo | Papel |
|---|---|
| `main.swift` / `AppDelegate.swift` | Entrada AppKit. `NSWindow` com a view SwiftUI dentro, e `NSStatusItem` com o menu (Abrir, Aplicativos, Atalhos, Sair). Fechar só esconde; com a janela escondida o app sai do Dock (`.accessory`). |
| `AppModel.swift` | Estado: lista de apps, app escolhido, volumes, capturas. Relê a lista a cada 1 s. Registra os atalhos. |
| `AudioApps.swift` | Lista os processos de áudio do Core Audio (`kAudioHardwarePropertyProcessObjectList`, macOS 14.2+), acha o app "de verdade" de cada processo (o próprio processo, o pai, ou um app cujo bundle ID é o começo do bundle ID do processo) e junta os auxiliares (Chrome Helper etc.). Esconde os terminais. |
| `AppVolumeTap.swift` | Volume por app (abaixo). |
| `GlobalHotkeys.swift` | Atalhos globais pelo Carbon `RegisterEventHotKey` (não pede permissão de Acessibilidade). A repetição ao segurar é feita por timer (0,4 s, depois a cada 0,08 s). |
| `ContentView.swift` / `VolumeBar.swift` / `Theme.swift` | Janela em SwiftUI no mesmo visual do Windows. |
| `MenuBarIcon.swift` | Ícone da barra de menus desenhado em código a partir das coordenadas do `icon.svg` (imagem "template"). |
| `Shortcuts.swift` | Lista de atalhos mostrada na janela e no menu. |
| `Resources/Info.plist` | Bundle `com.ppdrada.SoundTuneKey`, mínimo 14.2, texto da permissão de áudio (`NSAudioCaptureUsageDescription`). |
| `build-app.sh` | Compila e monta o `.app` (veja abaixo). |

**Volume por app no Mac:** o macOS não tem volume por app. Para cada app com volume abaixo de 100%:
1. Um **process tap** (`CATapDescription` com os processos do app, `muteBehavior = .mutedWhenTapped`) captura o som do app na origem e o silencia.
2. Um **dispositivo agregado privado** (saída padrão + o tap) recebe esse som.
3. Um IOProc copia o som da entrada para a saída multiplicado pelo volume.

Em 100% não existe captura: o app toca direto. A captura é refeita quando mudam os processos do app ou a saída padrão (fone, por exemplo). Se o Sound Tune Key fechar, o macOS desfaz tudo e o app volta ao volume normal. O volume ainda não fica salvo.

**Compilar e distribuir:**
- `mac/build-app.sh` gera `mac/build/SoundTuneKey.app`. Só precisa das ferramentas de linha de comando do Xcode.
- O app é **universal** (arm64 + x86_64). Sem o Xcode completo o SwiftPM não compila as duas arquiteturas juntas, então o script compila uma por vez (`--triple`) e junta com `lipo`.
- Assinatura **ad-hoc** (`codesign -s -`), grátis, só para o macOS aceitar rodar.
- `mac/build-app.sh zip` gera também `download/SoundTuneKey-mac.zip` (com `ditto`).

## Riscos e limitações conhecidos

| Risco | Onde | Detalhe / o que fazer |
|---|---|---|
| Aviso de segurança na primeira vez | Os dois | Sem assinatura paga. Windows: SmartScreen → "Mais informações → Executar assim mesmo". Mac: Gatekeeper → Ajustes → Privacidade e Segurança → "Abrir Mesmo Assim". O caminho do Mac com um download de verdade ainda não foi testado. |
| Smart App Control bloqueia o `.exe` local | Windows | No Debug, `UseAppHost=false` e roda via `dotnet SoundTuneKey.dll`. **Não mexer nessa configuração de segurança** do usuário. |
| Chrome e atalhos de sites (YouTube Music) | Os dois | Todo o som do Chrome sai de um processo só, então um app instalado pelo Chrome não se separa do Chrome. Alternativa: outro navegador só para ele. |
| Permissão "Gravação de áudio do sistema" | Mac | Sem ela, a captura não recebe som e o app fica mudo enquanto o volume estiver abaixo de 100%. Não há API pública para checar a permissão antes. |
| Ícone escondido atrás do recorte da câmera | Mac | Ícone novo entra na ponta esquerda da barra; com a barra cheia, fica atrás do notch. Na primeira vez o app grava `NSStatusItem Preferred Position SoundTuneKey = 300` (perto do Wi-Fi). É uma chave **não documentada** da Apple; testada no macOS 26. |
| Atalho global "rouba" a combinação | Os dois | `⌘⌥↑/↓` deixa de funcionar em outros apps (alguns editores usam) enquanto o Sound Tune Key está aberto. `⌘⌥←/→` foi evitado porque troca de abas nos navegadores. |
| Outra instância segura os atalhos | Os dois | Ao testar atalhos, feche as outras cópias do app antes. |
| Teclas de mídia do Mac | Mac | F7/F8/F9 controlam o app que está tocando agora (o macOS decide), não necessariamente o app escolhido. |
| Volume não persiste | Mac | Fechou o app, os volumes voltam a 100%. Fica resolvido na etapa de lembrar as configurações. |
| Captura refeita quando os processos mudam | Mac | O Chrome cria e fecha processos com frequência; cada mudança refaz a captura e pode dar um pequeno corte no som. |
