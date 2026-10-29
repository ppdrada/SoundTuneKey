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
| `AudioApps.cs` | Lista as sessões de áudio do dispositivo de saída padrão (NAudio / WASAPI) e junta as do mesmo processo numa linha (o Chrome tem várias). `SetVolume` muda o volume de todas as sessões do processo; `SetMute` liga o mudo do próprio Windows nelas (o volume fica guardado). |
| `MediaControls.cs` | Play/pause, próxima, anterior e voltar ao começo pelos controles de mídia do Windows (SMTC), casando a sessão de mídia (`SourceAppUserModelId`) com o nome do processo. `GetTimelineAsync` lê posição e duração; `SeekAsync` pula para um tempo. |
| `MediaIcons.cs` | Ícones ⏮ ⏯ ⏭ e alto-falante desenhados com `Graphics`; `MediaButton` (só o ícone, mãozinha, círculo ao passar o mouse e encolhimento ao clicar, animados por um timer de 16 ms) e `GlyphLabel` (ícone sem clique). |
| `PlayerPanel.cs` | Mini player: tempo (barra fina), ⏮ ▶ ⏭ juntos no meio (o play num círculo branco, mostrando ▶ ou ‖ pelo estado que o Windows informa) e volume. Duas instâncias: na janela e no topo do menu da bandeja. Só mostra e avisa (eventos); o estado fica na `MainForm`, que atualiza as duas. |
| `GlobalHotkeys.cs` | `RegisterHotKey` numa janela invisível; avisa se outro programa já usa o atalho. |
| `MainForm.cs` | Janela, lista, barra, bandeja e menu, toque duplo no `←`, abertura escondida com `--tray`. O app escolhido fica no campo `_current`, não na lista. |
| `VolumeBar.cs` / `Theme.cs` (o menu da bandeja no estilo do Windows 11: cantos e destaque arredondados, ícones da fonte de ícones do Windows) | Barra desenhada (usada no volume e, mais fina, no tempo: `TrackHeight`, `ThumbSize`, `Maximum`, evento `Released` ao soltar o mouse) e tema escuro (título escuro via DWM, ListView e menus desenhados). |
| `UpdateWindow.cs` (atualizar sozinho) | `Updates.InstallAsync` baixa o `.exe` novo ao lado do atual (`SoundTuneKey.new.exe`), confere que é um programa (começa com `MZ`, mais de 1 MB), renomeia o atual para `.exe.old` (o Windows deixa renomear o `.exe` aberto), põe o novo no lugar e o abre com `--after-update <pid>`; o novo espera o antigo fechar e apaga o `.old` (`Updates.FinishUpdate`). A versão de teste (`dotnet`) não se troca: o botão só abre o download. Na `MainForm`, a procura automática roda 15 s depois de abrir e uma vez por dia; o balão aparece uma vez por versão (`NotifiedVersion` no `settings.json`). |
| `UpdateWindow.cs` | "Sobre" e "Verificar atualizações..." (a mesma janela; a segunda já procura ao abrir): versão, autor, link do GitHub. Janela sem borda, de cantos arredondados (`Theme.UseRoundCorners`), que lê `download/version-windows.txt` no GitHub e compara com a `Version` do `.csproj`. |
| `ShortcutsWindow.cs` | Janelinha "Atalhos" (mesmo estilo do "Sobre") e a lista de atalhos mostrada nela. |
| `OsdWindow.cs` | Aviso na tela dos atalhos de volume e mudo: janela `WS_EX_LAYERED` + `UpdateLayeredWindow` (transparência por pixel, borda lisa), `WS_EX_TRANSPARENT`/`NOACTIVATE` (não pega clique nem foco), no monitor da janela da frente, some em ~1,5 s. Liga/desliga na caixinha "Aviso na tela" (linha do "Controlando") ou em "Mostrar aviso na tela" na bandeja (`ShowOsd` no `settings.json`). |
| `ToggleSwitch.cs` | Interruptor desenhado (trilha + bolinha que desliza) no lugar da caixinha de marcar; continua sendo um `CheckBox`. Usado no "Aviso na tela". `RoundCheck`, no mesmo arquivo, é a bolinha de marcar à esquerda do "Iniciar com o Windows"; no menu da bandeja, `Theme.UseDot` desenha a mesma bolinha nos itens de liga/desliga. |
| `Microphone.cs` | Mudo do microfone do Windows inteiro (`Ctrl+Alt+V`): `AudioEndpointVolume.Mute` do microfone padrão e do padrão de comunicação (o do Discord pode ser outro). O estado é relido ao abrir o menu e ao ativar a janela, porque o Windows ou o Discord podem mudar. |
| `AppList.cs` | A lista de apps: o botão direito só abre o menu (Mudo) e não seleciona a linha, para não trocar o app controlado. |
| `WindowsStartup.cs` | "Iniciar com o Windows": chave em `HKCU\...\Run` com `--tray`. |
| `AppSettings.cs` | Último app em `%AppData%\SoundTuneKey\settings.json`. |

**Volume por app:** nativo do Windows (`ISimpleAudioVolume` de cada sessão). O volume fica gravado pelo próprio Windows, mesmo com o Sound Tune Key fechado.

### Botões de mídia e barra de tempo

- **Botões ⏮ ⏯ ⏭**: chamam o mesmo código dos atalhos (`⏮` = `PreviousPressed`, com o toque duplo). Ficam no `PlayerPanel`, usado na janela e, dentro de um `ToolStripControlHost`, no topo do menu da bandeja. Clicar no mini player do menu **não fecha o menu**, de propósito (dá para clicar duas vezes no ⏮).
- **Barra de tempo**: o SMTC não avisa quando a música anda, então um timer de 500 ms lê `GetTimelineProperties()` **só com a janela visível ou o menu da bandeja aberto**. A posição informada vale para `LastUpdatedTime`; se está tocando, soma o tempo passado desde então. Arrastando, só o texto muda; o pulo (`TryChangePlaybackPositionAsync`, em ticks a partir de `StartTime`) acontece ao **soltar o mouse** (ou na hora, pelas setas do teclado). Testado com o Opera GX tocando vídeo.
- **No Mac**: veja "Botões de mídia e barra de tempo no Mac" abaixo.

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
| `Shortcuts.swift` | Lista de atalhos mostrada na janela e no menu, e o nome de cada atalho para o aviso de "outro programa já usa". |
| `MediaPlayer.swift` | Controles de mídia por AppleScript (`NSAppleScript`, scripts compilados uma vez) para o **Spotify** e o **Música**: estado, posição e duração (o Spotify dá a duração em ms), `playpause`, `next track`, `previous track`, `set player position`. Só fala com o player se ele já estiver aberto (o AppleScript abriria o app). |
| `ChromeMedia.swift` | Mídia do **Chrome**: executa JavaScript nas abas (`execute ... javascript`) para achar o `<video>`/`<audio>` (prefere o que está tocando) e ler/mudar `currentTime`, `paused`, `duration`. Guarda a aba encontrada e só procura de novo a cada 2 s (passa por todas as abas). ⏭ e o ⏮ duplo clicam nos botões do player do YouTube; em outros sites o ⏮ volta ao começo. `showSetup()` é o botão "Como ligar". |
| `MediaIcons.swift` | Ícones ⏮ ⏯ ⏭ e alto-falante desenhados com `Canvas`, nas mesmas formas do `MediaIcons.cs`; `MediaButton` com mãozinha, círculo ao passar o mouse e encolhimento ao clicar; `pointerCursor()` para qualquer item clicável. |
| `MenuMediaRow.swift` | Primeira linha do menu da barra (um `NSHostingView` dentro do `NSMenuItem`): tempo, ⏮ ⏯ ⏭ e volume, em cores do sistema (o menu segue claro/escuro). Clicar não fecha o menu. |
| `LoginItem.swift` | "Iniciar com o Mac" pelo `SMAppService.mainApp` (macOS 13+; aparece em Ajustes → Geral → Itens de Início). Aberto pelo login (evento de abertura com `keyAELaunchedAsLogInItem`) ou com `--tray`, o app começa escondido na barra de menus. |
| `Resources/Info.plist` | Bundle `com.ppdrada.SoundTuneKey`, mínimo 14.2, texto da permissão de áudio (`NSAudioCaptureUsageDescription`). |
| `build-app.sh` | Compila e monta o `.app` (veja abaixo). |

**Volume por app no Mac:** o macOS não tem volume por app. Para cada app com volume abaixo de 100%:
1. Um **process tap** (`CATapDescription` com os processos do app, `muteBehavior = .mutedWhenTapped`) captura o som do app na origem e o silencia.
2. Um **dispositivo agregado privado** (saída padrão + o tap) recebe esse som.
3. Um IOProc copia o som da entrada para a saída multiplicado pelo volume.

Em 100% não existe captura: o app toca direto. A captura é refeita quando mudam os processos do app ou a saída padrão (fone, por exemplo). Se o Sound Tune Key fechar, o macOS desfaz tudo e o app volta ao volume normal. O último app (`lastApp`) e os volumes (`volumes`) ficam no `UserDefaults` e são aplicados de novo quando o app abre.

**Botões de mídia e barra de tempo no Mac:** não há API pública para controlar a mídia de um app específico (o `MediaRemote` é privado e foi fechado para apps de terceiros), então o Sound Tune Key fala por AppleScript com o Spotify e o Música, e com o Chrome executando JavaScript no vídeo da aba; nos outros apps os botões ficam apagados e o tempo em `--:--`. O caminho de ler o "Tocando agora" do sistema pelo `MediaRemote` devolve vazio para apps de fora (macOS 15.4+); contornar isso pelo `perl` da Apple foi testado e **descartado**: burla uma proteção do macOS e quebra com atualizações. Como no Windows, o tempo é lido a cada 0,5 s **só enquanto a janela ou o menu estão à mostra** (timer no modo `.common`, para andar com o menu aberto); arrastando, só o texto muda e o pulo acontece ao soltar. O ⏮ tem o toque duplo (1 s). O `Info.plist` tem o `NSAppleEventsUsageDescription`; sem ele o macOS recusa os comandos sem perguntar.

**Compilar e distribuir:**
- `mac/build-app.sh` gera `mac/build/SoundTuneKey.app`. Só precisa das ferramentas de linha de comando do Xcode.
- O app é **universal** (arm64 + x86_64). Sem o Xcode completo o SwiftPM não compila as duas arquiteturas juntas, então o script compila uma por vez (`--triple`) e junta com `lipo`.
- Assinatura **ad-hoc** (`codesign -s -`), grátis, só para o macOS aceitar rodar.
- `mac/build-app.sh zip` gera também `download/SoundTuneKey-mac.zip` (com `ditto`).

## Riscos e limitações conhecidos

| Risco | Onde | Detalhe / o que fazer |
|---|---|---|
| Aviso de segurança na primeira vez | Os dois | Sem assinatura paga. Windows: SmartScreen → "Mais informações → Executar assim mesmo". Com o **Controle Inteligente de Aplicativos** ligado (é o caso do PC do usuário), o `.exe` é bloqueado sem opção de liberar, e cada versão nova é bloqueada de novo (arquivo novo, sem reputação); só assinatura de código ou desligar o controle resolvem. Mac: Gatekeeper → Ajustes → Privacidade e Segurança → "Abrir Mesmo Assim". O caminho do Mac com um download de verdade ainda não foi testado. |
| Telas com escalas diferentes (100% num monitor, 125% no outro) | Windows | O app é **PerMonitorV2** (`ApplicationHighDpiMode` no `.csproj`) com `AutoScaleMode.Dpi`: tudo é medido em pixels de 100% e o Windows amplia. O que é desenhado à mão (barras, ícones) multiplica pelo `Theme.Scale`. O menu da bandeja não amplia o que está dentro dele: o mini player é ampliado ao abrir o menu, pela escala do monitor onde o mouse clicou (`PlayerPanel.MenuScale`). Antes disso o app era "System aware" e ficava esticado e borrado no monitor de 125%. Testar abrindo a janela em cada monitor e movendo de um para o outro. |
| Smart App Control bloqueia o `.exe` local | Windows | No Debug, `UseAppHost=false` e roda via `dotnet SoundTuneKey.dll`. **Não mexer nessa configuração de segurança** do usuário. |
| Chrome e atalhos de sites (YouTube Music) | Os dois | Todo o som do Chrome sai de um processo só, então um app instalado pelo Chrome não se separa do Chrome. Alternativa: outro navegador só para ele. |
| Permissão "Gravação de áudio do sistema" | Mac | Sem ela, a captura não recebe som e o app fica mudo enquanto o volume estiver abaixo de 100%. Não há API pública para checar a permissão antes. |
| Ícone escondido atrás do recorte da câmera | Mac | Ícone novo entra na ponta esquerda da barra; com a barra cheia, fica atrás do notch. Na primeira vez o app grava `NSStatusItem Preferred Position SoundTuneKey = 300` (perto do Wi-Fi). É uma chave **não documentada** da Apple; testada no macOS 26. |
| Aviso na tela em tela cheia exclusiva | Windows | Jogos em tela cheia exclusiva não deixam nenhuma janela por cima; o aviso só aparece em janela/sem borda. |
| Atalho global "rouba" a combinação | Os dois | `⌘⌥↑/↓` deixa de funcionar em outros apps (alguns editores usam) enquanto o Sound Tune Key está aberto. `⌘⌥←/→` foi evitado porque troca de abas nos navegadores. |
| Outra instância segura os atalhos | Os dois | Ao testar atalhos, feche as outras cópias do app antes. |
| Teclas de mídia do Mac | Mac | F7/F8/F9 controlam o app que está tocando agora (o macOS decide), não necessariamente o app escolhido. Por isso há `⌃⌥P/→/←`, que controlam o app escolhido (Spotify, Música e vídeos do Chrome). `⌃⌥` são as teclas do VoiceOver: com o VoiceOver ligado, esses atalhos podem se misturar com os dele. |
| Volume só vale com o app aberto | Mac | Fechou o Sound Tune Key, os apps voltam a 100% até ele abrir de novo (os volumes ficam salvos). |
| Iniciar com o Mac guarda o lugar do app | Mac | O `SMAppService` registra o `.app` onde ele está. Se o usuário mover o app depois de ligar a caixinha, é preciso desligar e ligar de novo. Por isso o README pede para mover para Aplicativos antes. |
| Mídia só no Spotify, Música e Chrome | Mac | Os outros players não aceitam AppleScript para isso. O Chrome só aceita com **Ver → Desenvolvedor → Permitir o JavaScript do Eventos da Apple** ligado, **por perfil**; o app não liga isso por conta própria (é uma proteção do Chrome) e mostra o aviso com o botão "Como ligar". Uma aba de um perfil com a opção desligada não para a busca nas outras. Vídeos em iframes de outro site e transmissões ao vivo (duração infinita) não têm tempo. Na primeira vez o macOS pede a permissão de **Automação** (controlar o Spotify/Música); se o usuário negar, o erro -1743 vira um aviso na janela para liberar em Privacidade e Segurança → Automação. Testar sempre pelo `SoundTuneKey.app`: rodar o AppleScript num programa de teste pede a permissão em nome do Terminal/Claude. |
| Captura refeita quando os processos mudam | Mac | O Chrome cria e fecha processos com frequência; cada mudança refaz a captura e pode dar um pequeno corte no som. |
