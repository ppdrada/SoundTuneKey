using System.Drawing.Drawing2D;

namespace SoundTuneKey;

/// <summary>
/// Interruptor no lugar da caixinha de marcar: o texto e, à direita, a trilha com a bolinha que
/// desliza (clara = ligado, apagada = desligado). Continua sendo um CheckBox (Checked e
/// CheckedChanged funcionam igual), só o desenho muda.
/// </summary>
public class ToggleSwitch : CheckBox
{
    public const int TrackWidth = 34, TrackHeight = 18; // em pixels de 100%
    private const int Gap = 8;

    private readonly System.Windows.Forms.Timer _animation = new() { Interval = 16 };
    private float _knob; // 0 = esquerda (desligado), 1 = direita (ligado)

    public ToggleSwitch()
    {
        SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer, true);
        AutoSize = true;
        Cursor = Cursors.Hand;
        _animation.Tick += (_, _) => Animate();
    }

    // largura = texto + espaço + trilha; calculada na hora, então acompanha a escala da tela
    public override Size GetPreferredSize(Size proposedSize) => new(
        Padding.Horizontal + TextRenderer.MeasureText(Text, Font).Width + (int)((Gap + TrackWidth + 6) * Theme.Scale(this)), // +6: folga para o texto não ganhar reticências
        Math.Max(proposedSize.Height, (int)(28 * Theme.Scale(this))));

    protected override void OnCheckedChanged(EventArgs e)
    {
        base.OnCheckedChanged(e);
        if (IsHandleCreated && Visible)
            _animation.Start();
        else
            _knob = Checked ? 1 : 0;
    }

    private void Animate()
    {
        float target = Checked ? 1 : 0;
        _knob += (target - _knob) * 0.35f;
        if (Math.Abs(target - _knob) < 0.02f)
        {
            _knob = target;
            _animation.Stop();
        }
        Invalidate();
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.Clear(Parent?.BackColor ?? Theme.Background);
        float scale = Theme.Scale(this);
        float w = TrackWidth * scale, h = TrackHeight * scale;
        var track = new RectangleF(Width - Padding.Right - w, (Height - h) / 2f, w, h);

        var textBounds = new Rectangle(Padding.Left, 0, (int)(track.Left - Padding.Left - Gap * scale), Height);
        TextRenderer.DrawText(g, Text, Font, textBounds, Enabled ? Theme.MutedText : Theme.Inactive,
            TextFormatFlags.VerticalCenter | TextFormatFlags.Left | TextFormatFlags.EndEllipsis);

        Draw(g, track, _knob);
    }

    /// <summary>Desenha o interruptor; também usado no menu da bandeja.</summary>
    public static void Draw(Graphics g, RectangleF track, float knob)
    {
        var oldMode = g.SmoothingMode;
        g.SmoothingMode = SmoothingMode.AntiAlias;

        // a trilha passa de apagada para clara junto com a bolinha
        using (var trackBrush = new SolidBrush(Blend(Theme.Inactive, Theme.Text, knob)))
        using (var path = new GraphicsPath())
        {
            float d = track.Height;
            path.AddArc(track.X, track.Y, d, d, 90, 180);
            path.AddArc(track.Right - d, track.Y, d, d, 270, 180);
            path.CloseFigure();
            g.FillPath(trackBrush, path);
        }

        float inset = track.Height * 0.12f, size = track.Height - inset * 2;
        float x = track.X + inset + (track.Width - size - inset * 2) * knob;
        using (var knobBrush = new SolidBrush(Blend(Theme.MutedText, Theme.Background, knob)))
            g.FillEllipse(knobBrush, x, track.Y + inset, size, size);

        g.SmoothingMode = oldMode;
    }

    private static Color Blend(Color from, Color to, float t) => Color.FromArgb(
        (int)(from.R + (to.R - from.R) * t), (int)(from.G + (to.G - from.G) * t), (int)(from.B + (to.B - from.B) * t));

    protected override void Dispose(bool disposing)
    {
        if (disposing)
            _animation.Dispose();
        base.Dispose(disposing);
    }
}

/// <summary>
/// Caixinha de marcar redonda, à esquerda do texto: um anel vazio quando desmarcada e uma
/// bolinha clara dentro quando marcada. Usada no "Iniciar com o Windows" do rodapé.
/// </summary>
public class RoundCheck : CheckBox
{
    public const int Dot = 11; // em pixels de 100%
    private const int Gap = 7;

    public RoundCheck()
    {
        SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer, true);
        AutoSize = true;
        Cursor = Cursors.Hand;
    }

    public override Size GetPreferredSize(Size proposedSize) => new(
        Padding.Horizontal + (int)((Dot + Gap + 6) * Theme.Scale(this)) + TextRenderer.MeasureText(Text, Font).Width,
        Math.Max(proposedSize.Height, (int)(28 * Theme.Scale(this))));

    protected override void OnCheckedChanged(EventArgs e) { base.OnCheckedChanged(e); Invalidate(); }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.Clear(Parent?.BackColor ?? Theme.Background);
        float s = Theme.Scale(this), d = Dot * s;
        var ring = new RectangleF(Padding.Left + 1, (Height - d) / 2f, d, d);

        DrawDot(g, ring, Checked, s);

        var textBounds = new Rectangle((int)(ring.Right + Gap * s), 0, Width, Height);
        TextRenderer.DrawText(g, Text, Font, textBounds, Theme.MutedText, TextFormatFlags.VerticalCenter | TextFormatFlags.Left);
    }

    /// <summary>Desenha a bolinha (anel; com o miolo cheio quando marcada). Também usada no menu da bandeja.</summary>
    public static void DrawDot(Graphics g, RectangleF ring, bool isChecked, float scale)
    {
        var oldMode = g.SmoothingMode;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        using (var pen = new Pen(isChecked ? Theme.Text : Theme.MutedText, Math.Max(1.2f, 1.3f * scale)))
            g.DrawEllipse(pen, ring);
        if (isChecked)
        {
            float inner = ring.Width * 0.5f;
            using var fill = new SolidBrush(Theme.Text);
            g.FillEllipse(fill, ring.X + (ring.Width - inner) / 2, ring.Y + (ring.Height - inner) / 2, inner, inner);
        }
        g.SmoothingMode = oldMode;
    }
}
