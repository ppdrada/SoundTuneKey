using System.Diagnostics;

namespace SoundTuneKey;

/// <summary>Versão do app e a versão mais nova publicada no GitHub (download/version-windows.txt).</summary>
public static class Updates
{
    public const string DownloadUrl = "https://github.com/ppdrada/SoundTuneKey/raw/main/download/SoundTuneKey.exe";
    private const string VersionUrl = "https://raw.githubusercontent.com/ppdrada/SoundTuneKey/main/download/version-windows.txt";

    /// <summary>A versão deste .exe (o Version do .csproj), com 3 partes: 0.2.0.</summary>
    public static Version Current
    {
        get
        {
            var v = typeof(Updates).Assembly.GetName().Version!;
            return new Version(v.Major, v.Minor, v.Build);
        }
    }

    public static async Task<Version> LatestAsync()
    {
        using var http = new HttpClient { Timeout = TimeSpan.FromSeconds(10) };
        var text = await http.GetStringAsync(VersionUrl);
        return Version.Parse(text.Trim());
    }

    public const string RepoUrl = "https://github.com/ppdrada/SoundTuneKey";

    public static void Open(string url) => Process.Start(new ProcessStartInfo(url) { UseShellExecute = true });
}

/// <summary>
/// "Sobre" e "Verificar atualizações...": a mesma janelinha sem barra de título e com cantos
/// arredondados, como a do Discord. Mostra versão, autor e o link do GitHub; procura a versão nova
/// ao abrir (vinda de "Verificar atualizações...") ou pelo botão (vinda do "Sobre").
/// </summary>
public class UpdateWindow : Form
{
    private readonly Label _status = new()
    {
        Dock = DockStyle.Top,
        Height = 54,
        TextAlign = ContentAlignment.TopCenter,
        ForeColor = Theme.MutedText,
    };

    private readonly Button _download = new() { Text = "Baixar", Width = 150, Height = 32, Visible = false };
    private readonly Button _check = new() { Text = "Verificar atualizações", Width = 150, Height = 32 };
    private readonly Button _close = new() { Text = "Fechar", Width = 100, Height = 32 };
    private readonly Func<Task<Version>> _latest;

    /// <param name="latest">De onde vem a versão nova; o padrão é o GitHub (trocado nos testes).</param>
    /// <param name="checkNow">true: já procura ao abrir; false: espera o botão "Verificar atualizações".</param>
    public UpdateWindow(bool checkNow, Func<Task<Version>>? latest = null)
    {
        _latest = latest ?? Updates.LatestAsync;
        SuspendLayout();
        AutoScaleDimensions = new SizeF(96f, 96f);
        AutoScaleMode = AutoScaleMode.Dpi;

        Text = "Sobre o Sound Tune Key";
        FormBorderStyle = FormBorderStyle.None;
        StartPosition = FormStartPosition.CenterScreen;
        ClientSize = new Size(340, 380);
        BackColor = Theme.Background;
        ForeColor = Theme.Text;
        Icon = AppIcon.Load();
        KeyPreview = true;
        HandleCreated += (_, _) => Theme.UseRoundCorners(this);

        var logo = new PictureBox
        {
            Dock = DockStyle.Top,
            Height = 140,
            SizeMode = PictureBoxSizeMode.CenterImage,
            Image = new Icon(Icon, 128, 128).ToBitmap(), // o desenho do ícone tem margem: 128 px para o logo aparecer bem
            Padding = new Padding(0, 20, 0, 0),
        };
        var title = new Label
        {
            Dock = DockStyle.Top,
            Height = 34,
            Text = "Sound Tune Key",
            TextAlign = ContentAlignment.MiddleCenter,
            Font = new Font(Font.FontFamily, 13f, FontStyle.Bold),
        };

        var version = InfoLabel($"Versão {Updates.Current.ToString(3)}", Theme.Text);
        var author = InfoLabel("Desenvolvido por ppdrada", Theme.MutedText);
        var link = new LinkLabel
        {
            Dock = DockStyle.Top,
            Height = 30,
            Text = "github.com/ppdrada/SoundTuneKey",
            TextAlign = ContentAlignment.TopCenter,
            LinkColor = Theme.Text,
            ActiveLinkColor = Theme.MutedText,
            VisitedLinkColor = Theme.Text,
        };
        link.LinkClicked += (_, _) => Updates.Open(Updates.RepoUrl);

        Theme.Apply(_download);
        Theme.Apply(_check);
        Theme.Apply(_close);
        _download.Cursor = _check.Cursor = _close.Cursor = Cursors.Hand;
        var buttons = new FlowLayoutPanel
        {
            Dock = DockStyle.Bottom,
            Height = 56,
            FlowDirection = FlowDirection.RightToLeft,
            Padding = new Padding(0, 0, 30, 0),
        };
        buttons.Controls.Add(_close);
        buttons.Controls.Add(_check);
        buttons.Controls.Add(_download);

        // Dock = Top: o último adicionado fica em cima
        Controls.Add(_status);
        Controls.Add(link);
        Controls.Add(author);
        Controls.Add(version);
        Controls.Add(title);
        Controls.Add(logo);
        Controls.Add(buttons);
        ResumeLayout(false);

        _close.Click += (_, _) => Close();
        _download.Click += (_, _) => { Updates.Open(Updates.DownloadUrl); Close(); };
        _check.Click += async (_, _) => await CheckAsync();
        KeyDown += (_, e) => { if (e.KeyCode == Keys.Escape) Close(); };
        if (checkNow)
            Shown += async (_, _) => await CheckAsync();
    }

    private static Label InfoLabel(string text, Color color) => new()
    {
        Dock = DockStyle.Top,
        Height = 24,
        Text = text,
        ForeColor = color,
        TextAlign = ContentAlignment.MiddleCenter,
    };

    private async Task CheckAsync()
    {
        var current = Updates.Current;
        _check.Enabled = false;
        _status.ForeColor = Theme.MutedText;
        _status.Text = "Procurando atualizações…";
        try
        {
            var newest = await _latest();
            if (newest > current)
            {
                _status.ForeColor = Theme.Text;
                _status.Text = $"Versão {newest.ToString(3)} disponível!\nVocê está na {current.ToString(3)}.";
                _check.Visible = false;
                _download.Visible = true;
                AcceptButton = _download;
            }
            else
            {
                _status.Text = $"Você já tem a versão mais nova ({current.ToString(3)}).";
            }
        }
        catch (HttpRequestException ex) when (ex.StatusCode is not null)
        {
            // o GitHub respondeu (ex.: 404), então a internet está ok: falta o arquivo de versão lá
            _status.Text = "O GitHub ainda não informa a versão nova.\nTente de novo mais tarde.";
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException)
        {
            _status.Text = "Não deu para falar com o GitHub.\nConfira a internet e tente de novo.";
        }
        catch (Exception ex) when (ex is FormatException or ArgumentException)
        {
            _status.Text = "O GitHub respondeu algo inesperado.\nTente de novo mais tarde.";
        }
        finally
        {
            _check.Enabled = true;
        }
    }
}
