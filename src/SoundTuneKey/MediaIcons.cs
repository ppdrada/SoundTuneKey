using System.Drawing.Drawing2D;

namespace SoundTuneKey;

public enum MediaGlyph { Previous, PlayPause, Next, Speaker, SpeakerMuted, Play, Pause }

/// <summary>
/// Ícones desenhados em vez de caracteres como ⏮: as fontes deixam esses símbolos pequenos,
/// fora do centro ou coloridos (emoji), principalmente no menu da bandeja.
/// </summary>
public static class MediaIcons
{
    /// <summary>Desenha o ícone centrado em <paramref name="bounds"/>, num quadrado de <paramref name="size"/> pixels.</summary>
    public static void Draw(Graphics g, MediaGlyph glyph, Rectangle bounds, float size, Color color)
    {
        var oldMode = g.SmoothingMode;
        g.SmoothingMode = SmoothingMode.AntiAlias;

        float x = bounds.X + (bounds.Width - size) / 2f;
        float y = bounds.Y + (bounds.Height - size) / 2f;
        float s = size;

        using var brush = new SolidBrush(color);
        switch (glyph)
        {
            case MediaGlyph.Next:
                // ▶▶|
                g.FillPolygon(brush, Triangle(x, y, s * 0.42f, s, right: true));
                g.FillPolygon(brush, Triangle(x + s * 0.38f, y, s * 0.42f, s, right: true));
                g.FillRectangle(brush, x + s * 0.84f, y, s * 0.16f, s);
                break;

            case MediaGlyph.Previous:
                // |◀◀
                g.FillRectangle(brush, x, y, s * 0.16f, s);
                g.FillPolygon(brush, Triangle(x + s * 0.20f, y, s * 0.42f, s, right: false));
                g.FillPolygon(brush, Triangle(x + s * 0.58f, y, s * 0.42f, s, right: false));
                break;

            case MediaGlyph.PlayPause:
                // ▶ ‖
                g.FillPolygon(brush, Triangle(x, y, s * 0.5f, s, right: true));
                g.FillRectangle(brush, x + s * 0.62f, y, s * 0.14f, s);
                g.FillRectangle(brush, x + s * 0.86f, y, s * 0.14f, s);
                break;

            case MediaGlyph.Play:
                // ▶ (um pouco à direita do centro, para parecer centrado)
                g.FillPolygon(brush, Triangle(x + s * 0.12f, y, s * 0.86f, s, right: true));
                break;

            case MediaGlyph.Pause:
                // ‖
                g.FillRectangle(brush, x + s * 0.12f, y, s * 0.28f, s);
                g.FillRectangle(brush, x + s * 0.60f, y, s * 0.28f, s);
                break;

            case MediaGlyph.Speaker:
            case MediaGlyph.SpeakerMuted:
                // caixa + cone; ao lado, duas ondas de som ou um X (mudo)
                g.FillRectangle(brush, x, y + s * 0.34f, s * 0.2f, s * 0.32f);
                g.FillPolygon(brush,
                [
                    new PointF(x + s * 0.18f, y + s * 0.34f),
                    new PointF(x + s * 0.46f, y + s * 0.08f),
                    new PointF(x + s * 0.46f, y + s * 0.92f),
                    new PointF(x + s * 0.18f, y + s * 0.66f),
                ]);
                using (var pen = new Pen(color, Math.Max(1.5f, s * 0.09f)) { StartCap = LineCap.Round, EndCap = LineCap.Round })
                {
                    if (glyph == MediaGlyph.SpeakerMuted)
                    {
                        g.DrawLine(pen, x + s * 0.62f, y + s * 0.34f, x + s * 0.94f, y + s * 0.66f);
                        g.DrawLine(pen, x + s * 0.94f, y + s * 0.34f, x + s * 0.62f, y + s * 0.66f);
                    }
                    else
                    {
                        g.DrawArc(pen, x + s * 0.36f, y + s * 0.30f, s * 0.36f, s * 0.40f, -50, 100);
                        g.DrawArc(pen, x + s * 0.30f, y + s * 0.12f, s * 0.66f, s * 0.76f, -50, 100);
                    }
                }
                break;
        }

        g.SmoothingMode = oldMode;
    }

    private static PointF[] Triangle(float x, float y, float w, float h, bool right) => right
        ? [new(x, y), new(x + w, y + h / 2), new(x, y + h)]
        : [new(x + w, y), new(x, y + h / 2), new(x + w, y + h)];
}

/// <summary>
/// Botão de mídia como no Mac: só o ícone, com mãozinha, um círculo claro que aparece aos
/// poucos ao passar o mouse e o ícone encolhendo um pouco ao clicar.
/// </summary>
public class MediaButton : Control
{
    private const float PressedScale = 0.82f;
    private const float Speed = 0.25f; // quanto da animação anda a cada quadro (~60 por segundo)

    private MediaGlyph _glyph;
    private readonly float _glyphSize;
    private readonly System.Windows.Forms.Timer _animation = new() { Interval = 16 };

    private bool _hovered, _pressed;
    private float _hover;       // 0 = sem círculo, 1 = círculo inteiro
    private float _scale = 1f;  // tamanho do ícone

    public MediaButton(MediaGlyph glyph, float glyphSize)
    {
        _glyph = glyph;
        _glyphSize = glyphSize;
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer |
                 ControlStyles.UserPaint | ControlStyles.ResizeRedraw, true);
        SetStyle(ControlStyles.Selectable, false);
        Cursor = Cursors.Hand;
        _animation.Tick += (_, _) => Animate();
    }

    /// <summary>Botão principal (play/pause): círculo branco cheio com o ícone escuro, como no Spotify.</summary>
    [System.ComponentModel.DesignerSerializationVisibility(System.ComponentModel.DesignerSerializationVisibility.Hidden)]
    public bool Filled { get; set; }

    /// <summary>O ícone pode mudar (alto-falante normal ou mudo; ▶ ou ‖).</summary>
    [System.ComponentModel.DesignerSerializationVisibility(System.ComponentModel.DesignerSerializationVisibility.Hidden)]
    public MediaGlyph Glyph
    {
        get => _glyph;
        set { _glyph = value; Invalidate(); }
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.Clear(BackColor);

        if (Filled)
        {
            // o círculo inteiro encolhe ao clicar; ao passar o mouse ele fica um pouco maior
            g.SmoothingMode = SmoothingMode.AntiAlias;
            float size = _glyphSize * Theme.Scale(this);
            float d = Math.Min(Math.Min(Width, Height) - 2, size * 2.5f) * _scale * (1 + 0.06f * _hover);
            using var circle = new SolidBrush(Enabled ? Theme.Text : Theme.Inactive);
            g.FillEllipse(circle, (Width - d) / 2f, (Height - d) / 2f, d, d);
            MediaIcons.Draw(g, _glyph, ClientRectangle, size * 0.9f * _scale, Theme.Background);
            return;
        }

        if (_hover > 0.01f)
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            float glyphSize = _glyphSize * Theme.Scale(this);
            float d = Math.Min(Math.Min(Width, Height) - 2, glyphSize * 2.6f);
            using var circle = new SolidBrush(Color.FromArgb((int)(_hover * 255), Theme.Selection));
            g.FillEllipse(circle, (Width - d) / 2f, (Height - d) / 2f, d, d);
        }

        MediaIcons.Draw(g, _glyph, ClientRectangle, _glyphSize * Theme.Scale(this) * _scale, Enabled ? Theme.Text : Theme.Inactive);
    }

    protected override void OnMouseEnter(EventArgs e) { base.OnMouseEnter(e); _hovered = true; _animation.Start(); }
    protected override void OnMouseLeave(EventArgs e) { base.OnMouseLeave(e); _hovered = _pressed = false; _animation.Start(); }

    protected override void OnMouseDown(MouseEventArgs e)
    {
        base.OnMouseDown(e);
        if (e.Button == MouseButtons.Left) { _pressed = true; _animation.Start(); }
    }

    protected override void OnMouseUp(MouseEventArgs e)
    {
        base.OnMouseUp(e);
        _pressed = false;
        _animation.Start();
    }

    protected override void OnEnabledChanged(EventArgs e)
    {
        base.OnEnabledChanged(e);
        Cursor = Enabled ? Cursors.Hand : Cursors.Default;
        Invalidate();
    }

    private void Animate()
    {
        float hoverTarget = _hovered && Enabled ? 1f : 0f;
        float scaleTarget = _pressed && Enabled ? PressedScale : 1f;
        _hover += (hoverTarget - _hover) * Speed * 2;
        _scale += (scaleTarget - _scale) * Speed * 2;

        if (Math.Abs(_hover - hoverTarget) < 0.01f && Math.Abs(_scale - scaleTarget) < 0.005f)
        {
            _hover = hoverTarget;
            _scale = scaleTarget;
            _animation.Stop();
        }
        Invalidate();
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
            _animation.Dispose();
        base.Dispose(disposing);
    }
}
