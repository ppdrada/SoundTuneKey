# Sound Tune Key — instruções para o Claude

Controla o volume (e a mídia) de **um app escolhido** por atalhos globais, sem mexer no resto do sistema. Versão Windows em `src/`, versão Mac em `mac/`. Leia `docs/PRD.md` (o que o produto faz e o roteiro) e `docs/ARCHITECTURE.md` (como funciona e os riscos) antes de mudar algo.

## Como o usuário gosta de trabalhar

- Conversar em **português**, simples e direto, sem paredes de texto. Uma pergunta por vez.
- **Antes de construir**, confirmar o que ele quer. Recomendar uma opção em vez de listar tudo.
- Trabalhar em **etapas pequenas**, cada uma testável sozinha:
  1. Branch própria a partir da `main` atualizada: `feat/<nome>` (código) ou `docs/<nome>`.
  2. Implementar → compilar → **testar o que der por conta própria** → abrir o app para ele testar.
  3. Ao terminar, dizer o que mudou, o que foi testado e o que **não** foi testado.
  4. **Commit só depois que ele disser que testou e funcionou. Push só quando ele pedir.**
- Não abrir o painel lateral (diff/arquivo) por conta própria; só se ele pedir para ver.
- Não implementar ideias em aberto do PRD (como o aviso na tela) sem perguntar.

## Git e GitHub

- `main` é protegida: tudo entra por PR, que **ele abre e junta pelo navegador**. No PC Windows o `gh` está instalado e logado como `ppdrada`: dá para abrir e juntar o PR daqui, quando ele pedir. Sem `gh`, mande o link `https://github.com/ppdrada/SoundTuneKey/compare/main...<branch>?expand=1`.
- O remoto usa **SSH** (`git@github.com:ppdrada/SoundTuneKey.git`); a chave do Mac já entra como `ppdrada`.
- Commits em inglês, terminando com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` (o usuário autorizou o Claude como Contributor **neste projeto**).
- **Sem licença** no repositório (ele pode querer vender). Não adicionar sem perguntar.
- Não commitar arquivos de handoff (`HANDOFF.md`).

## Distribuição

- O binário fica no próprio Git, em `download/`, e o README aponta para `raw/main/download/...`. **Não citar a página de Releases** no README.
- Sem assinatura de código paga (escolha dele: grátis). O README explica como liberar o aviso de segurança.
- Ao mudar o app, gerar de novo o binário de `download/` na mesma etapa:
  - Mac: `mac/build-app.sh zip`
  - Windows (no PC Windows): `dotnet publish src/SoundTuneKey -c Release -o publish` e copiar o `.exe`. Ao publicar versão nova, subir juntos o `<Version>` do `.csproj` e o `download/version-windows.txt` (é ele que o "Verificar atualizações..." lê).

## README

- `README.md` (inglês, principal) e `README.pt-BR.md`, com a linha de bandeiras no topo e o logo do app no título.
- Cada seção (requisitos, atalhos, como usar, tecnologias) dividida em **Windows** e **macOS**. Os botões de download ficam lado a lado.
- O programa é em português; no README em inglês, os nomes de menu aparecem em português com a tradução ao lado.
- Sem aviso de "em desenvolvimento".

## Visual

Tema escuro com a paleta do ícone (tabela no PRD), janela de tamanho fixo, mesmo layout nos dois sistemas. O ícone é do usuário, em `assets/icon/`: **nunca criar outro**; derivar dele.

## Testar no Mac sem o usuário

- Compilar: `cd mac && swift build -c release`; montar e abrir: `mac/build-app.sh && open mac/build/SoundTuneKey.app` (feche a cópia aberta antes: `pkill -x SoundTuneKey`).
- O terminal **não tem permissão de gravar a tela** (`screencapture` falha). Para ver a janela, compile num programa descartável (no scratchpad) os arquivos do `mac/` com um `main.swift` que desenha `ContentView` com `ImageRenderer` e salva um PNG. O `ImageRenderer` não desenha `ScrollView`: troque por `VStack` numa cópia.
- Funções isoladas (como `AudioApps.list()`) também se testam com um `main.swift` descartável compilado com `swiftc`.
- A captura de áudio pede permissão **ao app que a cria**: teste volume no `SoundTuneKey.app`, não num programa de teste (a permissão iria para o terminal).
- O mesmo vale para o AppleScript do Spotify/Música (permissão de Automação). Cuidado: desenhar a `ContentView` num programa de teste com o Spotify escolhido já lê o tempo da música por AppleScript.
- Atalhos: dá para checar se a combinação está livre tentando `RegisterEventHotKey` num programa descartável; apertar as teclas fica com o usuário.

## Lições (não repetir)

- Guardar o app escolhido **no modelo**, nunca só na tela: no Windows a lista escondida perdia a seleção e os atalhos paravam.
- **Verificar o que já existe antes de criar** (o ícone foi duplicado uma vez no Windows).
- Testes de atalho falham em silêncio se outra instância do app estiver aberta.
- No Windows, não mexer no Smart App Control; o Debug roda sem apphost por causa dele.
- No Windows, o Debug (via `dotnet`) não pode atualizar o "Iniciar com o Windows" ao abrir: ele trocava a entrada do `.exe` de verdade pelo `dotnet.exe` e o fornecedor "ppdrada" sumia.
- No Windows, medidas novas na tela são em pixels de 100% (a janela amplia sozinha); o que for desenhado à mão usa `Theme.Scale`. Este PC tem um monitor a 100% e outro a 125%: teste nos dois. Fonte desenhada à mão (aviso na tela, mini player do menu) vai em **pixels** (`GraphicsUnit.Pixel`) vezes a escala: em pontos, num PC a 125%/150% o Windows já amplia e o texto saía gigante. O monitor principal daqui é 100%, então esse erro não aparece aqui.
- No Mac, `kAudioAggregateDeviceTapAutoStartKey` faz o `AudioDeviceStart` esperar o app tocar e trava a thread principal: não usar.
- No Mac, ícone novo da barra de menus some atrás do notch se a barra estiver cheia (resolvido com a posição inicial, veja ARCHITECTURE).
