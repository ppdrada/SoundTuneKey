using System.Drawing.Drawing2D;

namespace SoundTuneKey;

public enum MediaGlyph { Previous, PlayPause, Next, Speaker }

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

            case MediaGlyph.Speaker:
                // caixa + cone, e duas ondas de som
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
                    g.DrawArc(pen, x + s * 0.36f, y + s * 0.30f, s * 0.36f, s * 0.40f, -50, 100);
                    g.DrawArc(pen, x + s * 0.30f, y + s * 0.12f, s * 0.66f, s * 0.76f, -50, 100);
                }
                break;
        }

        g.SmoothingMode = oldMode;
    }

    private static PointF[] Triangle(float x, float y, float w, float h, bool right) => right
        ? [new(x, y), new(x + w, y + h / 2), new(x, y + h)]
        : [new(x + w, y), new(x, y + h / 2), new(x + w, y + h)];
}

/// <summary>Botão escuro com um <see cref="MediaGlyph"/> desenhado no centro.</summary>
public class MediaButton : Button
{
    private readonly MediaGlyph _glyph;
    private readonly float _glyphSize;

    public MediaButton(MediaGlyph glyph, float glyphSize)
    {
        _glyph = glyph;
        _glyphSize = glyphSize;
        Theme.Apply(this);
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e); // fundo e borda do tema; o texto fica vazio
        MediaIcons.Draw(e.Graphics, _glyph, ClientRectangle, _glyphSize, Enabled ? Theme.Text : Theme.Inactive);
    }
}

/// <summary>Ícone fixo, sem clique (o alto-falante ao lado da barra de volume).</summary>
public class GlyphLabel(MediaGlyph glyph, float glyphSize) : Control
{
    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e);
        MediaIcons.Draw(e.Graphics, glyph, ClientRectangle, glyphSize, Theme.MutedText);
    }
}
