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

    private const int VolumeStep = 5; // % por toque no atalho

    private readonly GlobalHotkeys _hotkeys = new();

    public MainForm()
    {
        Text = "Sound Tune Key";
        ClientSize = new Size(480, 420);
        StartPosition = FormStartPosition.CenterScreen;
        Icon = AppIcon.Load();

        _list.Columns.Add("Aplicativo", 220);
        _list.Columns.Add("Volume", 80);
        _list.Columns.Add("Status", 140);

        var volumeRow = new Panel { Dock = DockStyle.Fill };
        volumeRow.Controls.Add(_volume);
        volumeRow.Controls.Add(_volumeLabel);

        var volumePanel = new Panel { Dock = DockStyle.Bottom, Height = 76, Padding = new Padding(8, 4, 8, 4) };
        volumePanel.Controls.Add(volumeRow);
        volumePanel.Controls.Add(_selectedLabel);

        Controls.Add(_list);
        Controls.Add(volumePanel);
        Controls.Add(_refresh);

        _refresh.Click += (_, _) => LoadApps();
        _list.SelectedIndexChanged += (_, _) => ShowSelected();
        _volume.Scroll += (_, _) => ApplyVolume();
        Load += (_, _) => LoadApps();
        Shown += (_, _) => RegisterHotkeys();
        FormClosed += (_, _) => _hotkeys.Dispose();
    }

    private void RegisterHotkeys()
    {
        const HotkeyModifiers ctrlAlt = HotkeyModifiers.Control | HotkeyModifiers.Alt;
        var failed = new List<string>();

        // sem NoRepeat: segurar a tecla continua mudando o volume
        if (!_hotkeys.Register(ctrlAlt, Keys.Up, () => ChangeVolume(+VolumeStep)))
            failed.Add("Ctrl + Alt + ↑");
        if (!_hotkeys.Register(ctrlAlt, Keys.Down, () => ChangeVolume(-VolumeStep)))
            failed.Add("Ctrl + Alt + ↓");

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
        if (SelectedApp is null)
            return;

        _volume.Value = Math.Clamp(_volume.Value + delta, _volume.Minimum, _volume.Maximum);
        ApplyVolume();
    }

    private AudioApp? SelectedApp => _list.SelectedItems.Count > 0 ? (AudioApp)_list.SelectedItems[0].Tag! : null;

    private void LoadApps()
    {
        // mantém o mesmo app selecionado depois de atualizar
        var selectedName = SelectedApp?.ProcessName;

        _list.BeginUpdate();
        _list.Items.Clear();

        foreach (var app in AudioApps.List())
        {
            var item = new ListViewItem(app.DisplayName) { Tag = app };
            item.SubItems.Add(FormatVolume(app.Volume));
            item.SubItems.Add(app.IsPlaying ? "🔊 Tocando" : "Silencioso");
            _list.Items.Add(item);

            if (app.ProcessName == selectedName)
                item.Selected = true;
        }

        _list.EndUpdate();
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
            return;
        }

        _selectedLabel.Text = $"Controlando: {app.DisplayName}";
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

        var item = _list.SelectedItems[0];
        item.Tag = app with { Volume = volume };
        item.SubItems[1].Text = FormatVolume(volume);
        _volumeLabel.Text = FormatVolume(volume);
    }

    private static string FormatVolume(float volume) => $"{Math.Round(volume * 100)}%";
}
