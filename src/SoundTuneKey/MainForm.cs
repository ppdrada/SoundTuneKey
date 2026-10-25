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

    public MainForm()
    {
        Text = "Sound Tune Key";
        ClientSize = new Size(480, 360);
        StartPosition = FormStartPosition.CenterScreen;

        _list.Columns.Add("Aplicativo", 220);
        _list.Columns.Add("Volume", 80);
        _list.Columns.Add("Status", 140);

        Controls.Add(_list);
        Controls.Add(_refresh);

        _refresh.Click += (_, _) => LoadApps();
        Load += (_, _) => LoadApps();
    }

    private void LoadApps()
    {
        _list.BeginUpdate();
        _list.Items.Clear();

        foreach (var app in AudioApps.List())
        {
            var item = new ListViewItem(app.DisplayName) { Tag = app };
            item.SubItems.Add($"{Math.Round(app.Volume * 100)}%");
            item.SubItems.Add(app.IsPlaying ? "🔊 Tocando" : "Silencioso");
            _list.Items.Add(item);
        }

        _list.EndUpdate();
    }
}
