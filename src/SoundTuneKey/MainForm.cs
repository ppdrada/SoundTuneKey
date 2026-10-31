namespace SoundTuneKey;

public class MainForm : Form
{
    private readonly AppList _list = new()
    {
        Dock = DockStyle.Fill,
        View = View.Details,
        FullRowSelect = true,
        MultiSelect = false,
        HideSelection = false,
    };

    // o mesmo mini player na janela e no topo do menu da bandeja
    private readonly PlayerPanel _player = new(Theme.Background, glyphSize: 16f, buttonHeight: 44, new Padding(10, 0, 10, 14))
    {
        Dock = DockStyle.Bottom,
    };

    private readonly PlayerPanel _trayPlayer = new(Theme.Raised, glyphSize: 13f, buttonHeight: 36, new Padding(10, 8, 10, 12), volumeThumb: 14);

    private readonly Label _selectedLabel = new()
    {
        Dock = DockStyle.Fill,
        Padding = new Padding(8, 0, 0, 0),
        Text = "Selecione um app na lista",
        TextAlign = ContentAlignment.MiddleLeft,
    };

    private const int VolumeStep = 1; // % por toque no atalho (segurar a tecla repete)
    private const int VolumeColumnWidth = 80;
    private static readonly TimeSpan DoublePressWindow = TimeSpan.FromSeconds(1);

    private DateTime _lastPreviousPress = DateTime.MinValue;

    private readonly GlobalHotkeys _hotkeys = new();

    private readonly NotifyIcon _tray = new() { Text = "Sound Tune Key" };
    private bool _exiting;       // true só quando o usuário escolhe "Sair" na bandeja
    private bool _trayTipShown;  // o aviso "continua rodando" aparece uma vez só

    private readonly RoundCheck _startWithWindows = new()
    {
        Text = "Iniciar com o Windows",
        Dock = DockStyle.Left,
        AutoSize = true,
        Padding = new Padding(10, 0, 0, 0),
    };

    private readonly ToggleSwitch _showOsd = new()
    {
        Text = "Aviso na tela",
        Dock = DockStyle.Right,
        AutoSize = true,
        Padding = new Padding(0, 0, 10, 0),
    };

    private readonly AppSettings _settings = AppSettings.Load();
    private bool _startHidden;        // aberto pelo Windows com --tray: começa só na bandeja
    private bool _hotkeysRegistered;

    public MainForm(bool startHidden = false, bool justUpdated = false)
    {
        _startHidden = startHidden;

        // tudo abaixo é medido em pixels de 100%; o Windows aumenta junto em telas a 125%, 150%...
        // e de novo quando a janela muda para um monitor com outra escala
        SuspendLayout();
        AutoScaleDimensions = new SizeF(96f, 96f);
        AutoScaleMode = AutoScaleMode.Dpi;

        Text = "Sound Tune Key";
        // a lista fica do mesmo tamanho de antes; com os atalhos abertos a janela volta aos 500 de altura
        ClientSize = new Size(411, 340); // os atalhos ficam numa janelinha à parte (ShortcutsWindow)
        StartPosition = FormStartPosition.CenterScreen;
        Icon = AppIcon.Load();

        // tamanho fixo e só o X: ele já esconde na bandeja, como o minimizar faria
        FormBorderStyle = FormBorderStyle.FixedSingle;
        MaximizeBox = false;
        MinimizeBox = false;

        BackColor = Theme.Background;
        ForeColor = Theme.Text;
        HandleCreated += (_, _) => Theme.UseDarkTitleBar(this);
        Theme.Apply(_list);
        _showOsd.Checked = _settings.ShowOsd;
        _showOsd.CheckedChanged += (_, _) =>
        {
            _settings.ShowOsd = _showOsd.Checked;
            _settings.Save();
        };

        _list.Columns.Add("Aplicativo", 0);
        _list.Columns.Add("Volume", VolumeColumnWidth);
        _list.Resize += (_, _) => FitColumns();
        // a lista amplia as colunas sozinha ao mudar de escala; sem isso sobra uma rolagem horizontal
        _list.DpiChangedAfterParent += (_, _) => BeginInvoke(FitColumns);

        // Dock = Bottom: o último adicionado fica embaixo de tudo
        Controls.Add(_list);
        // linha do "Controlando: <app>", com a caixinha do aviso na tela à direita
        var selectedRow = new Panel { Dock = DockStyle.Bottom, Height = 34 };
        selectedRow.Controls.Add(_selectedLabel);
        selectedRow.Controls.Add(_showOsd);
        Controls.Add(selectedRow);
        Controls.Add(_player);
        Controls.Add(_updateBar);
        Controls.Add(BuildFooter());

        WindowsStartup.RefreshPath();
        _startWithWindows.Checked = WindowsStartup.IsEnabled;
        _startWithWindows.CheckedChanged += (_, _) => WindowsStartup.SetEnabled(_startWithWindows.Checked);

        _list.SelectedIndexChanged += (_, _) => OnListSelectionChanged();
        // no menu da bandeja, o app controlado aparece no próprio "Aplicativos" e muda junto
        _selectedLabel.TextChanged += (_, _) =>
            _appsMenu.Text = SelectedApp is { } app ? $"Aplicativos - Controlando: {app.DisplayName}" : "Aplicativos";
        SetupListMenu();
        foreach (var player in new[] { _player, _trayPlayer })
        {
            player.PreviousClicked += PreviousPressed;
            player.PlayPauseClicked += () => SendMedia(MediaCommand.PlayPause);
            player.NextClicked += () => SendMedia(MediaCommand.Next);
            player.SeekRequested += Seek;
            player.VolumeChanged += SetVolume;
            player.MuteClicked += ToggleMute;
        }

        // mãozinha em tudo que é clicável, como no Mac
        _list.Cursor = Cursors.Hand;

        _timelineTimer.Tick += (_, _) => RefreshTimeline();
        _appsTimer.Tick += (_, _) => RefreshAppsIfChanged();
        VisibleChanged += (_, _) => UpdateTimelineTimer();
        Load += (_, _) => LoadApps();
        Shown += (_, _) => RegisterHotkeys();
        FormClosing += OnFormClosing;
        Resize += (_, _) =>
        {
            if (WindowState == FormWindowState.Minimized)
                HideToTray();
        };
        FormClosed += (_, _) =>
        {
            _hotkeys.Dispose();
            _osd.Dispose();
            _tray.Dispose();
        };

        SetupTray();
        SetupUpdateNotice(justUpdated);
        SetupMicrophone();
        ResumeLayout(false);
    }

    // O Windows não avisa quando a música anda: o tempo é lido duas vezes por segundo, mas só
    // enquanto a janela ou o menu da bandeja estão à mostra.
    private readonly System.Windows.Forms.Timer _timelineTimer = new() { Interval = 500 };
    private bool _readingTimeline;
    private bool _trayMenuOpen;

    private void UpdateTimelineTimer()
    {
        _timelineTimer.Enabled = _appsTimer.Enabled = Visible || _trayMenuOpen;
        if (_timelineTimer.Enabled)
            RefreshTimeline();
    }

    // A lista de apps se atualiza sozinha: a cada 5 s, também só à mostra, e só é montada de novo
    // quando um app entrou, saiu, começou/parou de tocar ou mutou (assim não pisca).
    private readonly System.Windows.Forms.Timer _appsTimer = new() { Interval = 5000 };
    private readonly ToolStripMenuItem _appsMenu = new("Aplicativos");
    private string _appsSignature = "";

    private static string Signature(IEnumerable<AudioApp> apps) =>
        string.Join("|", apps.Select(a => $"{a.ProcessName}:{a.IsMuted}:{a.IsPlaying}:{a.HasAudio}"));

    private void RefreshAppsIfChanged()
    {
        if (Signature(AudioApps.List(withSilent: true)) == _appsSignature)
            return;
        if (Visible)
            LoadApps();
        // com o submenu do Mudo aberto, espera: montar de novo o fecharia na mão da pessoa
        if (_trayMenuOpen && !_appsMenu.DropDownItems.OfType<ToolStripMenuItem>().Any(i => i.DropDown.Visible))
            FillAppsMenu(_appsMenu);
    }

    private async void RefreshTimeline()
    {
        var app = SelectedApp;
        if (app is null)
        {
            ShowTimeline(null);
            return;
        }

        if (_readingTimeline)
            return;
        _readingTimeline = true;
        try
        {
            var timeline = await MediaControls.GetTimelineAsync(app.ProcessName);
            if (SelectedApp?.ProcessName == app.ProcessName)
                ShowTimeline(timeline);
        }
        catch (Exception ex) when (ex is not OutOfMemoryException)
        {
            System.Diagnostics.Debug.WriteLine($"Falha ao ler o tempo da música: {ex}");
        }
        finally
        {
            _readingTimeline = false;
        }
    }

    private void ShowTimeline(MediaTimeline? timeline)
    {
        _player.ShowTimeline(timeline);
        _trayPlayer.ShowTimeline(timeline);
    }

    private async void Seek(TimeSpan position)
    {
        var app = SelectedApp;
        if (app is null)
            return;

        try
        {
            await MediaControls.SeekAsync(app.ProcessName, position);
        }
        catch (Exception ex) when (ex is not OutOfMemoryException)
        {
            System.Diagnostics.Debug.WriteLine($"Falha ao mudar o tempo da música: {ex}");
        }
    }

    // Rodapé: "Iniciar com o Windows" à esquerda; "Atalhos" e "Sobre" à direita.
    private Panel BuildFooter()
    {
        var footer = new Panel { Dock = DockStyle.Bottom, Height = 32, Padding = new Padding(0, 0, 10, 2) }; // margem para não encostar na borda
        footer.Controls.Add(_startWithWindows);
        footer.Controls.Add(_micButton); // à esquerda de "Atalhos"
        footer.Controls.Add(FooterLink("Atalhos", ShowShortcutsWindow));
        footer.Controls.Add(FooterLink("Sobre", () => ShowAboutWindow(checkNow: false)));
        return footer;
    }

    private static LinkLabel FooterLink(string text, Action action)
    {
        var link = new LinkLabel
        {
            Text = text,
            Dock = DockStyle.Right,
            AutoSize = true,
            Padding = new Padding(8, 6, 0, 0),
            LinkBehavior = LinkBehavior.HoverUnderline,
            LinkColor = Theme.MutedText,
            ActiveLinkColor = Theme.Text,
        };
        link.LinkClicked += (_, _) => action();
        return link;
    }

    private ShortcutsWindow? _shortcutsWindow; // uma janela só, mesmo clicando várias vezes

    private void ShowShortcutsWindow()
    {
        if (_shortcutsWindow is null || _shortcutsWindow.IsDisposed)
        {
            _shortcutsWindow = new ShortcutsWindow();
            _shortcutsWindow.Show();
        }
        _shortcutsWindow.Activate();
    }

    private void SetupTray()
    {
        var appsMenu = _appsMenu;
        var startupItem = new ToolStripMenuItem("Iniciar com o Windows") { CheckOnClick = true };
        var osdItem = new ToolStripMenuItem("Mostrar aviso na tela") { CheckOnClick = true };
        Theme.UseDot(startupItem);
        Theme.UseDot(osdItem);
        // a caixinha da janela salva a escolha; as duas ficam sempre iguais
        osdItem.Click += (_, _) => _showOsd.Checked = osdItem.Checked;
        // o checkbox da janela grava no registro; os dois ficam sempre iguais
        startupItem.Click += (_, _) => _startWithWindows.Checked = startupItem.Checked;

        // No topo, como no mini player do Spotify e no Mac: tempo, ⏮ ⏯ ⏭ e volume.
        // Clicar nele não fecha o menu, então dá para voltar duas vezes ou pular várias.
        _trayPlayer.Width = 260; // em pixels de 100%
        _trayPlayer.MenuScale = 1f;
        var playerItem = new ToolStripControlHost(_trayPlayer)
        {
            AutoSize = false,
            Size = _trayPlayer.Size,
            Margin = Padding.Empty,
        };

        // no topo, como no Discord: o nome com o ícone, que abre o "Sobre"
        var aboutItem = new ToolStripMenuItem("Sound Tune Key", new Icon(Icon!, 16, 16).ToBitmap(), (_, _) => ShowAboutWindow(checkNow: false));

        var menu = new ContextMenuStrip();
        menu.Items.Add(aboutItem);
        menu.Items.Add(_updateItem);
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add(playerItem);
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add(_micItem);
        // em grupos, como no Windows 11: abrir/escolher, opções de liga/desliga, atualizar/sair
        appsMenu.Image = Theme.MenuIcon('\uE8FD');
        var openItem = menu.Items.Add("Abrir", Theme.MenuIcon('\uE8A7'), (_, _) => ShowFromTray());
        menu.Items.Add(appsMenu);
        var shortcutsItem = menu.Items.Add("Atalhos", Theme.MenuIcon('\uE765'), (_, _) => ShowShortcutsWindow());
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add(startupItem);
        menu.Items.Add(osdItem);
        menu.Items.Add(new ToolStripSeparator());
        var checkItem = menu.Items.Add("Verificar atualizações...", Theme.MenuIcon('\uE72C'), (_, _) => ShowAboutWindow(checkNow: true));
        var exitItem = menu.Items.Add("Sair", Theme.MenuIcon('\uE7E8'), (_, _) => ExitApp());
        Theme.Apply(menu);
        // o menu ignora a própria margem interna: o espaço embaixo vai no último item
        var lastItem = menu.Items[^1];
        lastItem.Padding = lastItem.Padding with { Bottom = lastItem.Padding.Bottom + 4 };
        Theme.Apply(appsMenu.DropDown);
        // só o que abre uma janela ou sai fecha o menu
        _menuClosers = [aboutItem, _updateItem, openItem, shortcutsItem, checkItem, exitItem];
        KeepOpenOnClick(menu);
        KeepOpenOnClick(appsMenu.DropDown);

        // a lista de apps é montada na hora em que o menu abre, para estar sempre atual
        menu.Opening += (_, _) =>
        {
            FillAppsMenu(appsMenu);
            startupItem.Checked = _startWithWindows.Checked;
            osdItem.Checked = _settings.ShowOsd;

            // o menu não amplia o que está dentro dele como a janela faz: o mini player acompanha a escala da tela
            float scale = Theme.ScaleAt(Cursor.Position); // o menu abre onde o ícone foi clicado
            float current = _trayPlayer.MenuScale ?? 1f;
            if (scale != current)
            {
                _trayPlayer.Scale(new SizeF(scale / current, scale / current));
                _trayPlayer.MenuScale = scale;
                playerItem.Size = _trayPlayer.Size;
            }
            // tamanho em pixels (12 px = 9 pt a 100%) vezes a escala: em pontos o Windows já amplia a
            // fonte pela escala do PC, e multiplicar de novo deixava o texto enorme em telas a 125%/150%
            _trayPlayer.Font = new Font(DefaultFont.FontFamily, 12f * scale, GraphicsUnit.Pixel);
            AppForHotkey(); // pode achar o último app, se ele abriu depois do Sound Tune Key
            ShowMicrophoneState(Microphone.IsMuted()); // pode ter sido mudado pelo Windows ou pelo Discord
            _trayMenuOpen = true;
            UpdateTimelineTimer();
        };
        menu.Closed += (_, _) =>
        {
            _trayMenuOpen = false;
            UpdateTimelineTimer();
        };

        _tray.Icon = Icon;
        _tray.ContextMenuStrip = menu;
        _tray.DoubleClick += (_, _) => ShowFromTray();
        _tray.Visible = true;
    }

    // Escolher e ligar/desligar no menu não o fecham, como no Mac: dá para ver o resultado e corrigir na hora.
    private HashSet<ToolStripItem> _menuClosers = [];
    private bool _keepMenuOpen;

    private void KeepOpenOnClick(ToolStripDropDown dropDown)
    {
        // o clique chega antes do fechamento, inclusive nos menus de cima quando é num submenu
        dropDown.ItemClicked += (_, e) => _keepMenuOpen = e.ClickedItem is not null && !_menuClosers.Contains(e.ClickedItem);
        dropDown.Closing += (_, e) =>
        {
            if (e.CloseReason == ToolStripDropDownCloseReason.ItemClicked && _keepMenuOpen)
                e.Cancel = true;
        };
    }

    private void FillAppsMenu(ToolStripMenuItem appsMenu)
    {
        appsMenu.DropDownItems.Clear();
        var selectedName = SelectedApp?.ProcessName;

        var apps = AudioApps.List(withSilent: true);
        _appsSignature = Signature(apps);
        if (apps.Count == 0)
            appsMenu.DropDownItems.Add(new ToolStripMenuItem("Nenhum app com som") { Enabled = false });

        foreach (var app in apps)
        {
            // tocando: espaços no fim guardam o lugar do alto-falante, desenhado pelo Theme (PlayingTag)
            var label = app.IsPlaying ? $"{app.DisplayName}      " : app.DisplayName;
            var item = new ToolStripMenuItem(label) { Checked = app.ProcessName == selectedName, Tag = app.IsPlaying ? Theme.PlayingTag : null };
            if (app.IsMuted)
                item.ForeColor = Theme.Mute; // app mudo aparece em vermelho
            else if (!app.HasAudio)
                item.ForeColor = Theme.MutedText; // aberto mas ainda sem som: cinza e sem o Mudo
            // clicar no nome escolhe o app; o ✓ muda na hora, com o menu aberto
            item.Click += (_, _) =>
            {
                SelectApp(app.ProcessName);
                foreach (var other in appsMenu.DropDownItems.OfType<ToolStripMenuItem>())
                    other.Checked = other == item;
            };
            if (app.HasAudio)
                item.DropDownItems.Add(MuteItem(app));
            Theme.Apply(item.DropDown);
            KeepOpenOnClick(item.DropDown);
            appsMenu.DropDownItems.Add(item);
        }

    }

    // "Mudo", marcado quando o app está mudo: no submenu da bandeja e no botão direito da lista
    private ToolStripMenuItem MuteItem(AudioApp app)
    {
        var mute = new ToolStripMenuItem("Mudo") { Checked = app.IsMuted };
        mute.Click += (_, _) =>
        {
            // o menu fica aberto: o estado vem do ✓, não do app guardado quando o menu abriu
            bool muted = !mute.Checked;
            SetMute(app, muted);
            mute.Checked = muted;
            if (mute.OwnerItem is ToolStripMenuItem appItem)
                appItem.ForeColor = muted ? Theme.Mute : Theme.Text;
        };
        return mute;
    }

    private void SetupListMenu()
    {
        var menu = new ContextMenuStrip();
        Theme.Apply(menu);
        KeepOpenOnClick(menu);
        // monta na hora, com o app que está embaixo do mouse; fora de um app, não abre
        menu.Opening += (_, e) =>
        {
            menu.Items.Clear();
            var item = _list.GetItemAt(_list.PointToClient(Cursor.Position).X, _list.PointToClient(Cursor.Position).Y);
            if (item is null || !((AudioApp)item.Tag!).HasAudio) // sem som ainda não tem mudo
            {
                e.Cancel = true;
                return;
            }
            menu.Items.Add(MuteItem((AudioApp)item.Tag!));
            e.Cancel = false; // menu vazio já chega aqui marcado para não abrir
        };
        _list.ContextMenuStrip = menu;
    }

    private void SelectApp(string processName) => LoadApps(select: processName);

    private UpdateWindow? _aboutWindow; // uma janela só, mesmo clicando várias vezes

    // ===== Microfone (Ctrl+Alt+V) =====
    // Mudo do microfone do Windows inteiro: ícone no rodapé, linha no menu da bandeja e aviso na tela.

    private readonly GlyphButton _micButton = new() { Dock = DockStyle.Right, Width = 30 };
    private readonly ToolStripMenuItem _micItem = new();
    private readonly ToolTip _footerTips = new();

    private void SetupMicrophone()
    {
        _footerTips.SetToolTip(_micButton, "Liga / desliga o microfone (Ctrl + Alt + V)");
        _micButton.Click += (_, _) => ToggleMicrophone(fromHotkey: false);
        _micItem.Click += (_, _) => ToggleMicrophone(fromHotkey: false);
        Activated += (_, _) => ShowMicrophoneState(Microphone.IsMuted());
        ShowMicrophoneState(Microphone.IsMuted());
    }

    private void ToggleMicrophone(bool fromHotkey)
    {
        var muted = Microphone.Toggle();
        ShowMicrophoneState(muted);
        if (fromHotkey && muted is bool m && _settings.ShowOsd)
            _osd.ShowMicrophone(m);
    }

    // null = sem microfone no PC: o ícone e a linha do menu somem
    private void ShowMicrophoneState(bool? muted)
    {
        _micButton.Visible = _micItem.Visible = muted is not null;
        if (muted is not bool m)
            return;
        _micButton.Set(m ? Theme.MicOffGlyph : Theme.MicGlyph, m ? Theme.Mute : Theme.MutedText);
        _micItem.Text = m ? "Microfone desligado" : "Microfone ligado";
        _micItem.ForeColor = m ? Theme.Mute : Theme.Text;
        _micItem.Image = Theme.MenuIcon((m ? Theme.MicOffGlyph : Theme.MicGlyph)[0], m ? Theme.Mute : Theme.MutedText);
    }

    // ===== Aviso de versão nova =====
    // Procura 15 s depois de abrir e depois uma vez por dia. Com versão nova: balão do Windows (uma vez
    // por versão), item no topo do menu da bandeja e faixa embaixo da janela; os três abrem a janelinha
    // de atualização, que baixa, troca o .exe e reabre o app sozinha.

    private readonly System.Windows.Forms.Timer _updateTimer = new() { Interval = 15_000 };
    private readonly ToolStripMenuItem _updateItem = new() { Visible = false, Image = Theme.MenuIcon('') };
    private readonly LinkLabel _updateBar = new()
    {
        Dock = DockStyle.Bottom,
        Height = 30,
        Visible = false,
        TextAlign = ContentAlignment.MiddleCenter,
        BackColor = Theme.Raised,
        LinkColor = Theme.Text,
        ActiveLinkColor = Theme.MutedText,
        LinkBehavior = LinkBehavior.HoverUnderline,
    };
    private bool _balloonOpensUpdate;

    private void SetupUpdateNotice(bool justUpdated)
    {
        _updateItem.Click += (_, _) => ShowAboutWindow(checkNow: true);
        _updateBar.LinkClicked += (_, _) => ShowAboutWindow(checkNow: true);
        _tray.BalloonTipClicked += (_, _) => { if (_balloonOpensUpdate) ShowAboutWindow(checkNow: true); };
        _updateTimer.Tick += (_, _) =>
        {
            _updateTimer.Interval = (int)TimeSpan.FromDays(1).TotalMilliseconds;
            CheckForUpdate();
        };
        _updateTimer.Start();

        if (justUpdated)
        {
            _balloonOpensUpdate = false;
            _tray.ShowBalloonTip(4000, "Sound Tune Key", $"Atualizado para a versão {Updates.Current.ToString(3)}.", ToolTipIcon.Info);
        }
    }

    private async void CheckForUpdate()
    {
        try
        {
            var newest = await Updates.LatestAsync();
            if (newest > Updates.Current)
                ShowUpdateAvailable(newest.ToString(3));
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or FormatException or ArgumentException)
        {
            // sem internet ou o GitHub fora: tenta de novo amanhã, sem incomodar
        }
    }

    private void ShowUpdateAvailable(string version)
    {
        _updateItem.Text = $"Atualizar para a versão {version}";
        _updateItem.Visible = true;
        _updateBar.Text = $"Versão {version} disponível · Atualizar";
        _updateBar.Visible = true;

        if (_settings.NotifiedVersion == version)
            return;
        _settings.NotifiedVersion = version;
        _settings.Save();
        _balloonOpensUpdate = true;
        _tray.ShowBalloonTip(5000, "Sound Tune Key", $"Versão {version} disponível. Clique aqui para atualizar.", ToolTipIcon.Info);
    }

    private void ShowAboutWindow(bool checkNow)
    {
        if (_aboutWindow is null || _aboutWindow.IsDisposed)
        {
            _aboutWindow = new UpdateWindow(checkNow);
            _aboutWindow.Show();
        }
        _aboutWindow.Activate();
    }

    // A coluna "Aplicativo" ocupa todo o espaço que sobra, para a linha ir até a borda da lista.
    // ClientSize já desconta a barra de rolagem quando ela aparece, então não surge rolagem horizontal.
    private void FitColumns()
    {
        if (_list.Columns.Count != 2)
            return;

        int volumeWidth = (int)(VolumeColumnWidth * Theme.Scale(_list));
        _list.Columns[1].Width = volumeWidth;
        _list.Columns[0].Width = Math.Max(100, _list.ClientSize.Width - volumeWidth);

        // as colunas cabem certinho, mas depois de mudar de escala a lista vazia guarda a rolagem
        // horizontal de antes do ajuste; ela nunca é necessária aqui
        if (_list.IsHandleCreated)
            ShowScrollBar(_list.Handle, SB_HORZ, false);
    }

    // Aberto com --tray: prepara tudo mas não mostra a janela. Como Load e Shown só disparam
    // quando a janela aparece, a lista e os atalhos são iniciados aqui.
    protected override void SetVisibleCore(bool value)
    {
        if (_startHidden)
        {
            _startHidden = false;
            CreateHandle();
            LoadApps();
            RegisterHotkeys();
            value = false;
        }

        base.SetVisibleCore(value);
    }

    // O X e o minimizar só escondem a janela: os atalhos continuam funcionando.
    private void OnFormClosing(object? sender, FormClosingEventArgs e)
    {
        if (_exiting || e.CloseReason != CloseReason.UserClosing)
            return;

        e.Cancel = true;
        HideToTray();
    }

    private void HideToTray()
    {
        Hide();

        if (!_trayTipShown)
        {
            _trayTipShown = true;
            _balloonOpensUpdate = false;
            _tray.ShowBalloonTip(3000, "Sound Tune Key",
                "Continua rodando aqui na bandeja. Os atalhos seguem funcionando.", ToolTipIcon.Info);
        }
    }

    private void ShowFromTray()
    {
        Show();
        WindowState = FormWindowState.Normal;
        Activate();
        LoadApps();
    }

    private void ExitApp()
    {
        _exiting = true;
        _tray.Visible = false;
        Close();
    }

    private void RegisterHotkeys()
    {
        // quando começa escondido, o Shown ainda dispara na primeira vez que a janela é aberta
        if (_hotkeysRegistered)
            return;
        _hotkeysRegistered = true;

        const HotkeyModifiers ctrlAlt = HotkeyModifiers.Control | HotkeyModifiers.Alt;
        var failed = new List<string>();

        // sem NoRepeat: segurar a tecla continua mudando o volume
        if (!_hotkeys.Register(ctrlAlt, Keys.Up, () => ChangeVolume(+VolumeStep)))
            failed.Add("Ctrl + Alt + ↑");
        if (!_hotkeys.Register(ctrlAlt, Keys.Down, () => ChangeVolume(-VolumeStep)))
            failed.Add("Ctrl + Alt + ↓");

        // com NoRepeat: segurar a tecla não pula várias músicas
        const HotkeyModifiers ctrlAltOnce = ctrlAlt | HotkeyModifiers.NoRepeat;
        if (!_hotkeys.Register(ctrlAltOnce, Keys.P, () => SendMedia(MediaCommand.PlayPause)))
            failed.Add("Ctrl + Alt + P");
        if (!_hotkeys.Register(ctrlAltOnce, Keys.Right, () => SendMedia(MediaCommand.Next)))
            failed.Add("Ctrl + Alt + →");
        if (!_hotkeys.Register(ctrlAltOnce, Keys.Left, PreviousPressed))
            failed.Add("Ctrl + Alt + ←");
        if (!_hotkeys.Register(ctrlAltOnce, Keys.M, () => { ToggleMute(); ShowOsd(); }))
            failed.Add("Ctrl + Alt + M");
        if (!_hotkeys.Register(ctrlAltOnce, Keys.A, NextApp))
            failed.Add("Ctrl + Alt + A");
        if (!_hotkeys.Register(ctrlAltOnce, Keys.V, () => ToggleMicrophone(fromHotkey: true)))
            failed.Add("Ctrl + Alt + V");

        if (failed.Count > 0)
        {
            MessageBox.Show(
                $"Não foi possível usar: {string.Join(", ", failed)}.\n\n" +
                "Outro programa já usa esse atalho (por exemplo, um script do AutoHotkey). Feche-o e abra o Sound Tune Key de novo.",
                "Sound Tune Key", MessageBoxButtons.OK, MessageBoxIcon.Warning);
        }
    }

    private void ChangeVolume(int delta)
    {
        var app = AppForHotkey();
        if (app is null)
            return;

        SetVolume(Math.Clamp(Percent(app.Volume) + delta, 0, 100));
        ShowOsd();
    }

    // Ctrl+Alt+A: passa para o próximo app da lista (os que estão tocando vêm primeiro) e mostra no aviso
    private void NextApp()
    {
        var apps = AudioApps.List();
        if (apps.Count == 0)
            return;

        int index = apps.FindIndex(a => a.ProcessName == SelectedApp?.ProcessName);
        SelectApp(apps[(index + 1) % apps.Count].ProcessName);
        ShowOsd();
    }

    private readonly OsdWindow _osd = new();

    // aviso na tela só pelos atalhos: com a janela aberta, a barra já mostra o volume
    private void ShowOsd()
    {
        if (_settings.ShowOsd && SelectedApp is { } app)
            _osd.ShowVolume(app.DisplayName, Percent(app.Volume), app.IsMuted);
    }

    // Um toque: volta para o começo da música. Dois toques em menos de 1 s: música anterior.
    private void PreviousPressed()
    {
        var now = DateTime.UtcNow;
        bool doublePress = now - _lastPreviousPress < DoublePressWindow;

        // depois de um toque duplo, o próximo toque começa a contagem de novo
        _lastPreviousPress = doublePress ? DateTime.MinValue : now;

        SendMedia(doublePress ? MediaCommand.Previous : MediaCommand.Restart);
    }

    private async void SendMedia(MediaCommand command)
    {
        // a mídia vale mesmo sem som ainda: o play do Spotify recém-aberto começa a tocar
        var app = AppForHotkey() ?? SelectedApp;
        if (app is null)
            return;

        try
        {
            // false = o app não tem controles de mídia (ex.: Discord); nesse caso não faz nada
            await MediaControls.SendAsync(app.ProcessName, command);
        }
        catch (Exception ex) when (ex is not OutOfMemoryException)
        {
            // um atalho nunca deve derrubar o programa
            System.Diagnostics.Debug.WriteLine($"Falha no comando de mídia {command}: {ex}");
        }
    }

    // O app controlado fica guardado aqui, e não só na seleção do ListView: quando o programa
    // abre escondido (--tray) a lista nunca foi exibida e não mantém a seleção.
    private AudioApp? _current;
    private bool _loadingList; // ignora os eventos de seleção enquanto a lista é recriada

    private AudioApp? SelectedApp => _current;

    private void OnListSelectionChanged()
    {
        if (_loadingList)
            return;

        _current = _list.SelectedItems.Count > 0 ? (AudioApp)_list.SelectedItems[0].Tag! : null;
        ShowSelected();
    }

    // Se o app salvo ainda não tocava quando o programa abriu (ex.: Spotify aberto depois do
    // Windows), o atalho atualiza a lista e tenta selecioná-lo de novo. Sem som ainda (cinza),
    // não há volume nem mudo para mexer: devolve null.
    private AudioApp? AppForHotkey()
    {
        if (SelectedApp is null or { HasAudio: false } && _settings.LastApp is not null)
            LoadApps();

        return SelectedApp is { HasAudio: true } app ? app : null;
    }

    private void LoadApps(string? select = null)
    {
        // mantém o mesmo app selecionado depois de atualizar; na primeira vez, usa o último app salvo
        var selectedName = select ?? _current?.ProcessName ?? _settings.LastApp;

        _loadingList = true;
        _list.BeginUpdate();
        _list.Items.Clear();
        _current = null;

        var apps = AudioApps.List(withSilent: true);
        _appsSignature = Signature(apps);
        foreach (var app in apps)
        {
            var item = new ListViewItem(app.DisplayName) { Tag = app };
            item.SubItems.Add(FormatVolume(app));
            _list.Items.Add(item);

            if (app.ProcessName == selectedName)
            {
                item.Selected = true;
                _current = app;
            }
        }

        _list.EndUpdate();
        FitColumns(); // a barra de rolagem pode ter aparecido ou sumido
        _loadingList = false;
        ShowSelected();
    }

    private void ShowSelected()
    {
        var app = SelectedApp;
        int? volume = app is { HasAudio: true } ? Percent(app.Volume) : null; // sem som ainda: barra desligada
        _player.SetApp(volume, app?.IsMuted ?? false);
        _trayPlayer.SetApp(volume, app?.IsMuted ?? false);
        RefreshTimeline();

        if (app is null)
        {
            _selectedLabel.Text = "Selecione um app na lista";
            _tray.Text = "Sound Tune Key";
            return;
        }

        if (_settings.LastApp != app.ProcessName)
        {
            _settings.LastApp = app.ProcessName;
            _settings.Save();
        }

        _selectedLabel.Text = app.HasAudio ? $"Controlando: {app.DisplayName}" : $"Controlando: {app.DisplayName} (sem som ainda)";
        _tray.Text = TrayText($"Sound Tune Key — {app.DisplayName}");
    }

    // vem da barra da janela, da barra do menu da bandeja ou dos atalhos
    private void SetVolume(int percent)
    {
        var app = SelectedApp;
        if (app is null)
            return;

        float volume = percent / 100f;
        // mexer no volume tira o mudo, como no Windows e no celular
        if (!AudioApps.SetVolume(app.ProcessName, volume) ||
            (app.IsMuted && !AudioApps.SetMute(app.ProcessName, false)))
        {
            // o app fechou ou parou de usar áudio
            LoadApps();
            return;
        }

        ShowAppChange(app with { Volume = volume, IsMuted = false });
    }

    // Ctrl+Alt+M ou clique no alto-falante; o volume fica guardado e volta ao tirar o mudo
    private void ToggleMute()
    {
        if (AppForHotkey() is { } app)
            SetMute(app, !app.IsMuted);
    }

    // também vem do botão direito na lista e do submenu de cada app na bandeja (qualquer app)
    private void SetMute(AudioApp app, bool muted)
    {
        if (!AudioApps.SetMute(app.ProcessName, muted))
        {
            LoadApps();
            return;
        }

        ShowAppChange(app with { IsMuted = muted });
    }

    private void ShowAppChange(AudioApp app)
    {
        if (app.ProcessName == _current?.ProcessName)
        {
            _current = app;
            _player.SetApp(Percent(app.Volume), app.IsMuted);
            _trayPlayer.SetApp(Percent(app.Volume), app.IsMuted);
        }

        foreach (ListViewItem item in _list.Items)
        {
            if (((AudioApp)item.Tag!).ProcessName != app.ProcessName)
                continue;

            item.Tag = app;
            item.SubItems[1].Text = FormatVolume(app);
            _list.RedrawItems(item.Index, item.Index, false); // redesenha a linha na hora: o nome muda de cor no mudo
        }
    }

    private const int SB_HORZ = 0;

    [System.Runtime.InteropServices.DllImport("user32.dll")]
    private static extern bool ShowScrollBar(IntPtr hWnd, int bar, bool show);

    private static int Percent(float volume) => (int)Math.Round(volume * 100);

    private static string FormatVolume(AudioApp app) => app.HasAudio ? $"{Percent(app.Volume)}%" : "—"; // mudo: o vermelho já mostra

    // o Windows limita o texto do ícone da bandeja a 127 caracteres
    private static string TrayText(string text) => text.Length <= 127 ? text : text[..126] + "…";
}
