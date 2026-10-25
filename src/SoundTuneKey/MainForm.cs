namespace SoundTuneKey;

public class MainForm : Form
{
    private readonly ListView _list = new()
    {
        Dock = DockStyle.Fill,
        View = View.Details,
        FullRowSelect = true,
        MultiSelect = false,
        HideSelection = false,
    };

    private readonly Button _refresh = new() { Text = "Atualizar lista", Dock = DockStyle.Bottom, Height = 36 };

    private readonly TrackBar _volume = new()
    {
        Dock = DockStyle.Fill,
        Minimum = 0,
        Maximum = 100,
        TickFrequency = 10,
        SmallChange = 5,
        LargeChange = 10,
        Enabled = false,
    };

    private readonly Label _volumeLabel = new()
    {
        Dock = DockStyle.Right,
        Width = 60,
        Text = "—",
        TextAlign = ContentAlignment.MiddleCenter,
    };

    private readonly Label _selectedLabel = new()
    {
        Dock = DockStyle.Top,
        Height = 24,
        Text = "Selecione um app na lista",
        TextAlign = ContentAlignment.MiddleLeft,
    };

    // mostrado na janela e no menu da bandeja, para quem não leu o README
    private static readonly (string Keys, string Action)[] Shortcuts =
    [
        ("Ctrl + Alt + ↑", "Aumenta o volume"),
        ("Ctrl + Alt + ↓", "Diminui o volume"),
        ("Ctrl + Alt + P", "Pausar / continuar"),
        ("Ctrl + Alt + →", "Próxima música"),
        ("Ctrl + Alt + ←", "Volta ao começo (2x rápido: música anterior)"),
    ];

    private const int VolumeStep = 5; // % por toque no atalho
    private static readonly TimeSpan DoublePressWindow = TimeSpan.FromSeconds(1);

    private DateTime _lastPreviousPress = DateTime.MinValue;

    private readonly GlobalHotkeys _hotkeys = new();

    private readonly NotifyIcon _tray = new() { Text = "Sound Tune Key" };
    private bool _exiting;       // true só quando o usuário escolhe "Sair" na bandeja
    private bool _trayTipShown;  // o aviso "continua rodando" aparece uma vez só

    private readonly CheckBox _startWithWindows = new()
    {
        Text = "Iniciar com o Windows",
        Dock = DockStyle.Bottom,
        Height = 28,
        Padding = new Padding(8, 0, 0, 0),
    };

    private readonly AppSettings _settings = AppSettings.Load();
    private bool _startHidden;        // aberto pelo Windows com --tray: começa só na bandeja
    private bool _hotkeysRegistered;

    public MainForm(bool startHidden = false)
    {
        _startHidden = startHidden;

        Text = "Sound Tune Key";
        ClientSize = new Size(480, 560);
        StartPosition = FormStartPosition.CenterScreen;
        Icon = AppIcon.Load();

        _list.Columns.Add("Aplicativo", 340);
        _list.Columns.Add("Volume", 100);

        var volumeRow = new Panel { Dock = DockStyle.Fill };
        volumeRow.Controls.Add(_volume);
        volumeRow.Controls.Add(_volumeLabel);

        var volumePanel = new Panel { Dock = DockStyle.Bottom, Height = 76, Padding = new Padding(8, 4, 8, 4) };
        volumePanel.Controls.Add(volumeRow);
        volumePanel.Controls.Add(_selectedLabel);

        Controls.Add(_list);
        Controls.Add(volumePanel);
        Controls.Add(_refresh);
        Controls.Add(BuildShortcutsBox());
        Controls.Add(_startWithWindows);

        WindowsStartup.RefreshPath();
        _startWithWindows.Checked = WindowsStartup.IsEnabled;
        _startWithWindows.CheckedChanged += (_, _) => WindowsStartup.SetEnabled(_startWithWindows.Checked);

        _refresh.Click += (_, _) => LoadApps();
        _list.SelectedIndexChanged += (_, _) => OnListSelectionChanged();
        _volume.Scroll += (_, _) => ApplyVolume();
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
            _tray.Dispose();
        };

        SetupTray();
    }

    private static GroupBox BuildShortcutsBox()
    {
        var table = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            ColumnCount = 2,
            RowCount = Shortcuts.Length,
        };
        table.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 120));
        table.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));

        foreach (var (keys, action) in Shortcuts)
        {
            table.Controls.Add(new Label { Text = keys, AutoSize = true, Font = new Font(Control.DefaultFont, FontStyle.Bold) });
            table.Controls.Add(new Label { Text = action, AutoSize = true });
        }

        var box = new GroupBox
        {
            Text = "Atalhos (funcionam com qualquer janela na frente)",
            Dock = DockStyle.Bottom,
            Height = 28 + Shortcuts.Length * 18,
            Padding = new Padding(8, 4, 8, 4),
        };
        box.Controls.Add(table);
        return box;
    }

    private static void ShowShortcutsDialog()
    {
        var lines = Shortcuts.Select(s => $"{s.Keys}    {s.Action}");
        MessageBox.Show(
            string.Join("\n", lines) + "\n\nOs atalhos controlam o app escolhido em Aplicativos.",
            "Sound Tune Key — Atalhos", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }

    private void SetupTray()
    {
        var appsMenu = new ToolStripMenuItem("Aplicativos");
        var startupItem = new ToolStripMenuItem("Iniciar com o Windows") { CheckOnClick = true };
        // o checkbox da janela grava no registro; os dois ficam sempre iguais
        startupItem.Click += (_, _) => _startWithWindows.Checked = startupItem.Checked;

        var menu = new ContextMenuStrip();
        menu.Items.Add("Abrir", null, (_, _) => ShowFromTray());
        menu.Items.Add(appsMenu);
        menu.Items.Add("Atalhos", null, (_, _) => ShowShortcutsDialog());
        menu.Items.Add(startupItem);
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add("Sair", null, (_, _) => ExitApp());

        // a lista de apps é montada na hora em que o menu abre, para estar sempre atual
        menu.Opening += (_, _) =>
        {
            FillAppsMenu(appsMenu);
            startupItem.Checked = _startWithWindows.Checked;
        };

        _tray.Icon = Icon;
        _tray.ContextMenuStrip = menu;
        _tray.DoubleClick += (_, _) => ShowFromTray();
        _tray.Visible = true;
    }

    private void FillAppsMenu(ToolStripMenuItem appsMenu)
    {
        appsMenu.DropDownItems.Clear();
        var selectedName = SelectedApp?.ProcessName;

        var apps = AudioApps.List();
        if (apps.Count == 0)
        {
            appsMenu.DropDownItems.Add(new ToolStripMenuItem("Nenhum app com som") { Enabled = false });
            return;
        }

        foreach (var app in apps)
        {
            var label = app.IsPlaying ? $"{app.DisplayName}  🔊" : app.DisplayName;
            var item = new ToolStripMenuItem(label) { Checked = app.ProcessName == selectedName };
            item.Click += (_, _) => SelectApp(app.ProcessName);
            appsMenu.DropDownItems.Add(item);
        }
    }

    private void SelectApp(string processName) => LoadApps(select: processName);

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
        if (AppForHotkey() is null)
            return;

        _volume.Value = Math.Clamp(_volume.Value + delta, _volume.Minimum, _volume.Maximum);
        ApplyVolume();
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
        var app = AppForHotkey();
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
    // Windows), o atalho atualiza a lista e tenta selecioná-lo de novo.
    private AudioApp? AppForHotkey()
    {
        if (SelectedApp is null && _settings.LastApp is not null)
            LoadApps();

        return SelectedApp;
    }

    private void LoadApps(string? select = null)
    {
        // mantém o mesmo app selecionado depois de atualizar; na primeira vez, usa o último app salvo
        var selectedName = select ?? _current?.ProcessName ?? _settings.LastApp;

        _loadingList = true;
        _list.BeginUpdate();
        _list.Items.Clear();
        _current = null;

        foreach (var app in AudioApps.List())
        {
            var item = new ListViewItem(app.DisplayName) { Tag = app };
            item.SubItems.Add(FormatVolume(app.Volume));
            _list.Items.Add(item);

            if (app.ProcessName == selectedName)
            {
                item.Selected = true;
                _current = app;
            }
        }

        _list.EndUpdate();
        _loadingList = false;
        ShowSelected();
    }

    private void ShowSelected()
    {
        var app = SelectedApp;
        _volume.Enabled = app is not null;

        if (app is null)
        {
            _selectedLabel.Text = "Selecione um app na lista";
            _volumeLabel.Text = "—";
            _tray.Text = "Sound Tune Key";
            return;
        }

        if (_settings.LastApp != app.ProcessName)
        {
            _settings.LastApp = app.ProcessName;
            _settings.Save();
        }

        _selectedLabel.Text = $"Controlando: {app.DisplayName}";
        _tray.Text = TrayText($"Sound Tune Key — {app.DisplayName}");
        _volume.Value = (int)Math.Round(app.Volume * 100);
        _volumeLabel.Text = FormatVolume(app.Volume);
    }

    private void ApplyVolume()
    {
        var app = SelectedApp;
        if (app is null)
            return;

        float volume = _volume.Value / 100f;
        if (!AudioApps.SetVolume(app.ProcessName, volume))
        {
            // o app fechou ou parou de usar áudio
            LoadApps();
            return;
        }

        _current = app with { Volume = volume };
        _volumeLabel.Text = FormatVolume(volume);

        foreach (ListViewItem item in _list.Items)
        {
            if (((AudioApp)item.Tag!).ProcessName != app.ProcessName)
                continue;

            item.Tag = _current;
            item.SubItems[1].Text = FormatVolume(volume);
        }
    }

    private static string FormatVolume(float volume) => $"{Math.Round(volume * 100)}%";

    // o Windows limita o texto do ícone da bandeja a 127 caracteres
    private static string TrayText(string text) => text.Length <= 127 ? text : text[..126] + "…";
}
