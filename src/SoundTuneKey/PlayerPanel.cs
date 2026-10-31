namespace SoundTuneKey;

/// <summary>
/// Mini player do app escolhido, de cima para baixo: tempo da música, ⏮ ⏯ ⏭ e volume (a mesma
/// ordem do Mac). Usado na janela e no topo do menu da bandeja; quem guarda o estado é a MainForm.
/// </summary>
public sealed class PlayerPanel : Panel
{
    public event Action? PreviousClicked;
    public event Action? PlayPauseClicked;
    public event Action? NextClicked;
    public event Action<TimeSpan>? SeekRequested;
    public event Action<int>? VolumeChanged; // 0 a 100
    public event Action? MuteClicked;

    private const int LabelWidth = 46;

    private readonly VolumeBar _timeline = new()
    {
        Dock = DockStyle.Fill,
        Enabled = false,
        TrackHeight = 3,  // mais fina e discreta que a de volume
        ThumbSize = 10,
        Maximum = 1,
    };

    private readonly VolumeBar _volume;
    private readonly Label _elapsed, _duration, _volumeText;
    private readonly List<MediaButton> _buttons = [];
    private readonly MediaButton _speaker;
    private readonly MediaButton _playPause, _previous, _next;
    private readonly ToolTip _toolTip = new();
    private readonly float _glyphSize;

    /// <summary>Escala da tela quando o mini player está no menu da bandeja; null na janela.</summary>
    [System.ComponentModel.DesignerSerializationVisibility(System.ComponentModel.DesignerSerializationVisibility.Hidden)]
    public float? MenuScale { get; set; }

    /// <param name="volumeThumb">tamanho da bolinha da barra de volume (menor no menu da bandeja)</param>
    public PlayerPanel(Color background, float glyphSize, int buttonHeight, Padding padding, int volumeThumb = 18)
    {
        _volume = new() { Dock = DockStyle.Fill, Enabled = false, ThumbSize = volumeThumb, KeyStep = 1 }; // setas: 1% por vez, como o atalho
        _glyphSize = glyphSize;
        BackColor = background;
        _timeline.BackColor = _volume.BackColor = background;

        // a bolinha do tempo é menor (12 x 18): os tempos ficam 3 px mais largos para as trilhas começarem juntas
        _elapsed = SideLabel(DockStyle.Left, LabelWidth + 3, "--:--");
        _duration = SideLabel(DockStyle.Right, LabelWidth + 3, "--:--");
        _volumeText = SideLabel(DockStyle.Right, LabelWidth, "—");

        var timeRow = new Panel { Dock = DockStyle.Top, Height = 26 };
        timeRow.Controls.Add(_timeline);
        timeRow.Controls.Add(_elapsed);
        timeRow.Controls.Add(_duration);

        // ⏮ ▶ ⏭ juntos no meio (colunas vazias dos lados), com o play em destaque num círculo branco
        var buttonRow = new TableLayoutPanel { Dock = DockStyle.Top, Height = buttonHeight, ColumnCount = 5, RowCount = 1 };
        buttonRow.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 50));
        buttonRow.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, buttonHeight * 2.4f));
        buttonRow.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, buttonHeight * 1.5f));
        buttonRow.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, buttonHeight * 2.4f));
        buttonRow.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 50));
        _playPause = Button(MediaGlyph.Play, () => PlayPauseClicked?.Invoke());
        _previous = Button(MediaGlyph.Previous, () => PreviousClicked?.Invoke());
        _next = Button(MediaGlyph.Next, () => NextClicked?.Invoke());
        _playPause.Filled = true;
        buttonRow.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
        buttonRow.Controls.Add(_previous, 1, 0);
        buttonRow.Controls.Add(_playPause, 2, 0);
        buttonRow.Controls.Add(_next, 3, 0);

        // alto-falante: deixa claro que a barra de baixo é o volume, e não o tempo da música;
        // clicar nele liga e desliga o mudo. Fica à esquerda, alinhado com o tempo de cima.
        _speaker = Button(MediaGlyph.Speaker, () => MuteClicked?.Invoke());
        _speaker.Dock = DockStyle.Left;
        _speaker.Width = 30;
        var volumeRow = new Panel { Dock = DockStyle.Top, Height = 28 };
        volumeRow.Controls.Add(_volume);
        volumeRow.Controls.Add(new Panel { Dock = DockStyle.Left, Width = LabelWidth - 30 });
        volumeRow.Controls.Add(_speaker);
        volumeRow.Controls.Add(_volumeText);

        // Dock = Top: o último adicionado fica em cima
        // um respiro entre os botões e a barra de volume
        var gap = new Panel { Dock = DockStyle.Top, Height = 8 };
        Controls.Add(volumeRow);
        Controls.Add(gap);
        Controls.Add(buttonRow);
        Controls.Add(timeRow);
        // altura em pixels de 100%; em telas ampliadas a janela aumenta tudo junto (AutoScaleMode.Dpi)
        Padding = padding;
        Height = padding.Vertical + timeRow.Height + buttonRow.Height + gap.Height + volumeRow.Height;

        _timeline.Scroll += (_, _) =>
        {
            _elapsed.Text = FormatTime(TimeSpan.FromSeconds(_timeline.Value));
            if (!_timeline.IsDragging) // setas do teclado: pula na hora
                SeekRequested?.Invoke(TimeSpan.FromSeconds(_timeline.Value));
        };
        _timeline.Released += (_, _) => SeekRequested?.Invoke(TimeSpan.FromSeconds(_timeline.Value));
        _volume.Scroll += (_, _) => VolumeChanged?.Invoke(_volume.Value);
    }

    /// <summary>Liga os botões e a barra de volume quando há um app escolhido.</summary>
    public void SetApp(int? volumePercent, bool muted = false)
    {
        bool hasApp = volumePercent is not null;
        foreach (var button in _buttons)
            button.Enabled = hasApp;

        _volume.Enabled = hasApp;
        if (volumePercent is int percent)
            _volume.Value = percent;
        _volumeText.Text = hasApp ? $"{volumePercent}%" : "—";
        _speaker.Glyph = hasApp && muted ? MediaGlyph.SpeakerMuted : MediaGlyph.Speaker;

        // mudo: só o alto-falante fica vermelho; a barra fica apagada (o volume guardado continua aparecendo)
        bool mutedNow = hasApp && muted;
        _volume.Accent = mutedNow ? Theme.MutedBar : Theme.Text;
        _speaker.Tint = mutedNow ? Theme.Mute : Theme.Text;
    }

    /// <summary>null = o app não informa o tempo (ex.: Discord): a barra fica apagada.</summary>
    public void ShowTimeline(MediaTimeline? timeline)
    {
        if (_timeline.IsDragging)
            return;

        _timeline.Enabled = timeline is not null;
        // ‖ enquanto toca, ▶ quando está pausado (ou quando o app não informa)
        _playPause.Glyph = timeline?.IsPlaying == true ? MediaGlyph.Pause : MediaGlyph.Play;
        if (timeline is null)
        {
            _timeline.Value = 0;
            _elapsed.Text = _duration.Text = "--:--";
            return;
        }

        _timeline.Maximum = (int)Math.Ceiling(timeline.Duration.TotalSeconds);
        _timeline.Value = (int)timeline.Position.TotalSeconds;
        _elapsed.Text = FormatTime(timeline.Position);
        _duration.Text = FormatTime(timeline.Duration);
    }

    /// <summary>Dicas dos botões no idioma escolhido (chamado de novo quando ele muda).</summary>
    public void ApplyTexts()
    {
        _toolTip.SetToolTip(_playPause, Lang.T("Pausar / continuar", "Play / pause"));
        _toolTip.SetToolTip(_previous, Lang.T("Volta ao começo (2x rápido: música anterior)", "Back to start (twice quickly: previous track)"));
        _toolTip.SetToolTip(_next, Lang.T("Próxima música", "Next track"));
        _toolTip.SetToolTip(_speaker, Lang.T("Mudo / volta o som (Ctrl + Alt + M)", "Mute / unmute (Ctrl + Alt + M)"));
    }

    private MediaButton Button(MediaGlyph glyph, Action action)
    {
        var button = new MediaButton(glyph, _glyphSize) { Dock = DockStyle.Fill, Enabled = false, BackColor = BackColor };
        button.Click += (_, _) => action();
        _buttons.Add(button);
        return button;
    }

    private Label SideLabel(DockStyle dock, int width, string text) => new()
    {
        Dock = dock,
        Width = width,
        Text = text,
        ForeColor = Theme.MutedText,
        BackColor = BackColor,
        TextAlign = dock == DockStyle.Left ? ContentAlignment.MiddleLeft : ContentAlignment.MiddleRight,
    };

    private static string FormatTime(TimeSpan time) =>
        time.TotalHours >= 1 ? time.ToString(@"h\:mm\:ss") : time.ToString(@"m\:ss");
}
