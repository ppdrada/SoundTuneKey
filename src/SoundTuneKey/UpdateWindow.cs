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

    /// <summary>Argumento do .exe novo: espera o antigo (pelo id do processo) fechar antes de abrir.</summary>
    public const string AfterUpdateArgument = "--after-update";

    /// <summary>A versão de teste roda pelo "dotnet": essa não se troca sozinha.</summary>
    public static bool CanSelfUpdate =>
        !Path.GetFileName(Environment.ProcessPath!).Equals("dotnet.exe", StringComparison.OrdinalIgnoreCase);

    /// <summary>
    /// Baixa o .exe novo ao lado do atual, troca os dois e abre o novo. Depois disso o app atual
    /// precisa fechar (o novo espera por ele). O Windows deixa renomear o .exe que está aberto.
    /// </summary>
    /// <param name="exePath">o .exe a trocar; o padrão é o próprio app (o teste usa um arquivo falso)</param>
    public static async Task InstallAsync(IProgress<int> progress, string downloadUrl = DownloadUrl, string? exePath = null, bool start = true)
    {
        var exe = exePath ?? Environment.ProcessPath!;
        var newExe = Path.Combine(Path.GetDirectoryName(exe)!, "SoundTuneKey.new.exe");
        var oldExe = exe + ".old";

        using (var http = new HttpClient { Timeout = TimeSpan.FromMinutes(5) })
        using (var response = await http.GetAsync(downloadUrl, HttpCompletionOption.ResponseHeadersRead))
        {
            response.EnsureSuccessStatusCode();
            long total = response.Content.Headers.ContentLength ?? 0;
            await using var source = await response.Content.ReadAsStreamAsync();
            await using var target = File.Create(newExe);
            var buffer = new byte[81920];
            long done = 0;
            int read;
            while ((read = await source.ReadAsync(buffer)) > 0)
            {
                await target.WriteAsync(buffer.AsMemory(0, read));
                done += read;
                if (total > 0)
                    progress.Report((int)(done * 100 / total));
            }
        }

        if (!LooksLikeProgram(newExe))
        {
            File.Delete(newExe);
            throw new InvalidDataException("O arquivo baixado não é o programa.");
        }

        File.Move(exe, oldExe, overwrite: true);
        try
        {
            File.Move(newExe, exe);
        }
        catch
        {
            File.Move(oldExe, exe); // não deu para pôr o novo no lugar: volta o antigo
            throw;
        }

        if (start)
            Process.Start(new ProcessStartInfo(exe, $"{AfterUpdateArgument} {Environment.ProcessId}") { UseShellExecute = false });
    }

    // um .exe começa com "MZ" e o nosso tem dezenas de MB; uma página de erro não passa nisso
    public static bool LooksLikeProgram(string path)
    {
        using var file = File.OpenRead(path);
        return file.Length > 1_000_000 && file.ReadByte() == 'M' && file.ReadByte() == 'Z';
    }

    /// <summary>
    /// No começo do .exe novo: espera o antigo fechar (para soltar os atalhos e o ícone da bandeja)
    /// e apaga a cópia antiga. Devolve true se este é o primeiro início depois de uma atualização.
    /// </summary>
    public static bool FinishUpdate(string[] args)
    {
        if (!CanSelfUpdate)
            return false; // versão de teste (dotnet): não há .exe para limpar
        int i = Array.IndexOf(args, AfterUpdateArgument);
        if (i >= 0 && i + 1 < args.Length && int.TryParse(args[i + 1], out int oldPid))
        {
            try { Process.GetProcessById(oldPid).WaitForExit(10_000); }
            catch (ArgumentException) { } // já fechou
        }

        var oldExe = Environment.ProcessPath + ".old";
        for (int attempt = 0; attempt < 10 && File.Exists(oldExe); attempt++)
        {
            try { File.Delete(oldExe); }
            catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { Thread.Sleep(300); }
        }

        return i >= 0;
    }
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

    // a versão de teste não se troca sozinha: nela o botão só abre o download no navegador
    private readonly Button _download = new() { Width = 150, Height = 32, Visible = false };
    private readonly Button _check = new() { Width = 150, Height = 32 };
    private readonly Button _close = new() { Width = 100, Height = 32 };
    private readonly Label _version, _author;
    private readonly LinkLabel _portuguese, _english, _spanish; // escolha do idioma do app inteiro
    private readonly Func<Task<Version>> _latest;

    /// <param name="latest">De onde vem a versão nova; o padrão é o GitHub (trocado nos testes).</param>
    /// <param name="checkNow">true: já procura ao abrir; false: espera o botão "Verificar atualizações".</param>
    public UpdateWindow(bool checkNow, Func<Task<Version>>? latest = null)
    {
        _latest = latest ?? Updates.LatestAsync;
        SuspendLayout();
        AutoScaleDimensions = new SizeF(96f, 96f);
        AutoScaleMode = AutoScaleMode.Dpi;


        FormBorderStyle = FormBorderStyle.None;
        StartPosition = FormStartPosition.CenterScreen;
        ClientSize = new Size(340, 410);
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

        var version = _version = InfoLabel("", Theme.Text);
        var author = _author = InfoLabel("", Theme.MutedText);
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

        // Português · English · Español, centrados: o escolhido em branco, os outros em cinza (clareiam ao passar o mouse)
        _portuguese = LanguageLink("Português", "pt");
        _english = LanguageLink("English", "en");
        _spanish = LanguageLink("Español", "es");
        var dot1 = new Label { Text = "·", AutoSize = true, ForeColor = Theme.MutedText };
        var dot2 = new Label { Text = "·", AutoSize = true, ForeColor = Theme.MutedText };
        var languages = new Panel { Dock = DockStyle.Top, Height = 30 };
        Control[] row = [_portuguese, dot1, _english, dot2, _spanish];
        languages.Controls.AddRange(row);
        languages.Layout += (_, _) =>
        {
            int x = (languages.Width - row.Sum(c => c.Width)) / 2;
            foreach (var c in row)
            {
                c.Location = new Point(x, 0);
                x += c.Width;
            }
        };

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
        Controls.Add(languages);
        Controls.Add(link);
        Controls.Add(author);
        Controls.Add(version);
        Controls.Add(title);
        Controls.Add(logo);
        Controls.Add(buttons);
        ResumeLayout(false);

        ApplyTexts();
        Lang.Changed += ApplyTexts;
        FormClosed += (_, _) => Lang.Changed -= ApplyTexts;

        _close.Click += (_, _) => Close();
        _download.Click += async (_, _) => await UpdateNowAsync();
        _check.Click += async (_, _) => await CheckAsync();
        KeyDown += (_, e) => { if (e.KeyCode == Keys.Escape) Close(); };
        if (checkNow)
            Shown += async (_, _) => await CheckAsync();
    }

    private bool _selfUpdateFailed;

    // trocar o idioma aqui vale na hora, nesta janela e no resto do app
    private void ApplyTexts()
    {
        Text = Lang.T("Sobre o Sound Tune Key", "About Sound Tune Key", "Acerca de Sound Tune Key");
        _version.Text = Lang.T("Versão ", "Version ", "Versión ") + Updates.Current.ToString(3);
        _author.Text = Lang.T("Desenvolvido por ppdrada", "Made by ppdrada", "Hecho por ppdrada");
        // a versão de teste não se troca sozinha: nela o botão só abre o download no navegador
        _download.Text = Updates.CanSelfUpdate && !_selfUpdateFailed ? Lang.T("Atualizar agora", "Update now", "Actualizar ahora") : Lang.T("Baixar", "Download", "Descargar");
        _check.Text = Lang.T("Verificar atualizações", "Check for updates", "Buscar actualizaciones");
        _close.Text = Lang.T("Fechar", "Close", "Cerrar");
        _portuguese.LinkColor = Lang.Code == "pt" ? Theme.Text : Theme.MutedText;
        _english.LinkColor = Lang.Code == "en" ? Theme.Text : Theme.MutedText;
        _spanish.LinkColor = Lang.Code == "es" ? Theme.Text : Theme.MutedText;
    }

    private LinkLabel LanguageLink(string text, string code)
    {
        var link = new LinkLabel
        {
            Text = text,
            AutoSize = true,
            LinkBehavior = LinkBehavior.NeverUnderline,
            ActiveLinkColor = Theme.Text,
            Cursor = Cursors.Hand,
        };
        link.MouseEnter += (_, _) => link.LinkColor = Theme.Text;
        link.MouseLeave += (_, _) => ApplyTexts(); // volta à cor de escolhido ou não
        link.LinkClicked += (_, _) => Lang.Set(code);
        return link;
    }

    private async Task UpdateNowAsync()
    {
        if (!Updates.CanSelfUpdate || _selfUpdateFailed)
        {
            Updates.Open(Updates.DownloadUrl);
            Close();
            return;
        }

        _download.Enabled = _close.Enabled = false;
        _status.ForeColor = Theme.Text;
        try
        {
            await Updates.InstallAsync(new Progress<int>(p => _status.Text = Lang.T($"Baixando a versão nova… {p}%", $"Downloading the new version… {p}%", $"Descargando la nueva versión… {p}%")));
            _status.Text = Lang.T("Pronto! Abrindo a versão nova…", "Done! Opening the new version…", "¡Listo! Abriendo la nueva versión…");
            Application.Exit(); // o .exe novo já abriu e espera este fechar
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or IOException or UnauthorizedAccessException or InvalidDataException)
        {
            // sem permissão na pasta, sem internet...: o download pelo navegador continua funcionando
            _status.Text = Lang.T("Não deu para atualizar sozinho.\nClique em Baixar para pegar pelo navegador.",
                "Couldn't update by itself.\nClick Download to get it in the browser.",
                "No se pudo actualizar sola.\nHaz clic en Descargar para obtenerla en el navegador.");
            _download.Text = Lang.T("Baixar", "Download", "Descargar");
            _download.Enabled = _close.Enabled = true;
            _selfUpdateFailed = true; // o próximo clique só abre o navegador
        }
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
        _status.Text = Lang.T("Procurando atualizações…", "Checking for updates…", "Buscando actualizaciones…");
        try
        {
            var newest = await _latest();
            if (newest > current)
            {
                _status.ForeColor = Theme.Text;
                _status.Text = Lang.T($"Versão {newest.ToString(3)} disponível!\nVocê está na {current.ToString(3)}.",
                    $"Version {newest.ToString(3)} available!\nYou have {current.ToString(3)}.",
                    $"¡Versión {newest.ToString(3)} disponible!\nTienes la {current.ToString(3)}.");
                _check.Visible = false;
                _download.Visible = true;
                AcceptButton = _download;
            }
            else
            {
                _status.Text = Lang.T($"Você já tem a versão mais nova ({current.ToString(3)}).", $"You already have the latest version ({current.ToString(3)}).", $"Ya tienes la versión más reciente ({current.ToString(3)}).");
            }
        }
        catch (HttpRequestException ex) when (ex.StatusCode is not null)
        {
            // o GitHub respondeu (ex.: 404), então a internet está ok: falta o arquivo de versão lá
            _status.Text = Lang.T("O GitHub ainda não informa a versão nova.\nTente de novo mais tarde.", "GitHub doesn't list the new version yet.\nTry again later.", "GitHub aún no muestra la nueva versión.\nInténtalo de nuevo más tarde.");
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException)
        {
            _status.Text = Lang.T("Não deu para falar com o GitHub.\nConfira a internet e tente de novo.", "Couldn't reach GitHub.\nCheck the internet and try again.", "No se pudo conectar con GitHub.\nRevisa tu conexión a internet e inténtalo de nuevo.");
        }
        catch (Exception ex) when (ex is FormatException or ArgumentException)
        {
            _status.Text = Lang.T("O GitHub respondeu algo inesperado.\nTente de novo mais tarde.", "GitHub sent an unexpected answer.\nTry again later.", "GitHub dio una respuesta inesperada.\nInténtalo de nuevo más tarde.");
        }
        finally
        {
            _check.Enabled = true;
        }
    }
}
