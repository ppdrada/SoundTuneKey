using System.Drawing.Drawing2D;
using System.Drawing.Text;
using System.Runtime.InteropServices;

namespace SoundTuneKey;

/// <summary>
/// Aviso na tela ao apertar um atalho de volume ou mudo: uma pílula escura embaixo, no meio do
/// monitor do jogo, que some sozinha. Não rouba o foco nem o clique (o mouse passa através).
/// Desenhada com transparência por pixel (UpdateLayeredWindow), para a borda arredondada ficar lisa.
/// Em jogos de tela cheia exclusiva nenhum programa aparece por cima; em janela sem borda funciona.
/// </summary>
public class OsdWindow : Form
{
    private const int Width100 = 300, Height100 = 56; // tamanho em pixels de 100%
    private static readonly TimeSpan Visible100 = TimeSpan.FromSeconds(1.2);
    private const byte StartAlpha = 255;

    private readonly System.Windows.Forms.Timer _timer = new() { Interval = 16 };
    private DateTime _shownAt;
    private Bitmap? _frame;
    private Point _position;

    public OsdWindow()
    {
        FormBorderStyle = FormBorderStyle.None;
        ShowInTaskbar = false;
        StartPosition = FormStartPosition.Manual;
        _timer.Tick += (_, _) => Fade();
    }

    protected override bool ShowWithoutActivation => true;

    protected override CreateParams CreateParams
    {
        get
        {
            const int WS_EX_LAYERED = 0x80000, WS_EX_TRANSPARENT = 0x20, WS_EX_TOOLWINDOW = 0x80,
                      WS_EX_NOACTIVATE = 0x8000000, WS_EX_TOPMOST = 0x8;
            var cp = base.CreateParams;
            cp.ExStyle |= WS_EX_LAYERED | WS_EX_TRANSPARENT | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE | WS_EX_TOPMOST;
            return cp;
        }
    }

    /// <summary>Mostra (ou atualiza, se já estiver na tela) o aviso com o volume do app.</summary>
    public void ShowVolume(string appName, int volumePercent, bool muted)
    {
        // o monitor do jogo: o da janela que está na frente
        var screen = Screen.FromHandle(GetForegroundWindow());
        float scale = Theme.ScaleAt(new Point(screen.Bounds.Left + screen.Bounds.Width / 2, screen.Bounds.Top + screen.Bounds.Height / 2));
        var size = new Size((int)(Width100 * scale), (int)(Height100 * scale));
        _position = new Point(screen.Bounds.Left + (screen.Bounds.Width - size.Width) / 2,
                              screen.Bounds.Bottom - size.Height - (int)(90 * scale));

        _frame?.Dispose();
        _frame = Draw(size, scale, appName, volumePercent, muted);

        if (!Visible)
            Show();
        Apply(StartAlpha);
        _shownAt = DateTime.UtcNow;
        _timer.Start();
    }

    // fica parado um pouco e depois some aos poucos
    private void Fade()
    {
        var fadeTime = (DateTime.UtcNow - _shownAt - Visible100).TotalMilliseconds;
        if (fadeTime <= 0)
            return;

        double left = 1 - fadeTime / 300;
        if (left <= 0)
        {
            _timer.Stop();
            Hide();
            return;
        }
        Apply((byte)(StartAlpha * left));
    }

    private static Bitmap Draw(Size size, float scale, string appName, int volumePercent, bool muted)
    {
        var bmp = new Bitmap(size.Width, size.Height, System.Drawing.Imaging.PixelFormat.Format32bppArgb);
        using var g = Graphics.FromImage(bmp);
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
        float S(float v) => v * scale;

        using (var pill = Rounded(new RectangleF(0.5f, 0.5f, size.Width - 1, size.Height - 1), size.Height / 2f))
        {
            using var fill = new SolidBrush(Color.FromArgb(240, Theme.Background));
            using var border = new Pen(Theme.Border);
            g.FillPath(fill, pill);
            g.DrawPath(border, pill);
        }

        MediaIcons.Draw(g, muted ? MediaGlyph.SpeakerMuted : MediaGlyph.Speaker,
            Rectangle.Round(new RectangleF(S(22), 0, S(16), size.Height)), S(13), Theme.Text);

        using var small = new Font("Segoe UI", 9f * scale);
        using var big = new Font("Segoe UI", 10f * scale, FontStyle.Bold);
        using (var gray = new SolidBrush(Theme.MutedText))
            g.DrawString(appName, small, gray, new RectangleF(S(52), S(7), S(180), S(18)), new StringFormat { Trimming = StringTrimming.EllipsisCharacter, FormatFlags = StringFormatFlags.NoWrap });

        var track = new RectangleF(S(54), S(34), S(170), S(6));
        using (var rest = new SolidBrush(Theme.Inactive))
        using (var restPath = Rounded(track, track.Height / 2))
            g.FillPath(rest, restPath);
        if (!muted && volumePercent > 0)
        {
            var filled = track with { Width = track.Width * volumePercent / 100f };
            using var fill = new SolidBrush(Theme.Text);
            using var fillPath = Rounded(filled, Math.Min(track.Height / 2, filled.Width / 2));
            g.FillPath(fill, fillPath);
        }

        using (var text = new SolidBrush(Theme.Text))
            g.DrawString(muted ? "Mudo" : $"{volumePercent}%", big, text,
                new RectangleF(S(228), 0, S(66), size.Height),
                new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center, FormatFlags = StringFormatFlags.NoWrap });

        return bmp;
    }

    // Manda o desenho para a janela com transparência por pixel e a opacidade geral (para sumir aos poucos).
    private void Apply(byte alpha)
    {
        if (_frame is null)
            return;

        var screenDc = GetDC(IntPtr.Zero);
        var memDc = CreateCompatibleDC(screenDc);
        var hBitmap = _frame.GetHbitmap(Color.FromArgb(0));
        var old = SelectObject(memDc, hBitmap);
        try
        {
            var size = new SIZE { cx = _frame.Width, cy = _frame.Height };
            var src = new POINT();
            var dst = new POINT { x = _position.X, y = _position.Y };
            var blend = new BLENDFUNCTION { BlendOp = 0, BlendFlags = 0, SourceConstantAlpha = alpha, AlphaFormat = 1 };
            const int ULW_ALPHA = 2;
            UpdateLayeredWindow(Handle, screenDc, ref dst, ref size, memDc, ref src, 0, ref blend, ULW_ALPHA);
        }
        finally
        {
            SelectObject(memDc, old);
            DeleteObject(hBitmap);
            DeleteDC(memDc);
            ReleaseDC(IntPtr.Zero, screenDc);
        }
    }

    private static GraphicsPath Rounded(RectangleF r, float radius)
    {
        var path = new GraphicsPath();
        float d = radius * 2;
        if (d <= 0) { path.AddRectangle(r); return path; }
        path.AddArc(r.X, r.Y, d, d, 180, 90);
        path.AddArc(r.Right - d, r.Y, d, d, 270, 90);
        path.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
        path.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
        path.CloseFigure();
        return path;
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            _timer.Dispose();
            _frame?.Dispose();
        }
        base.Dispose(disposing);
    }

    [StructLayout(LayoutKind.Sequential)] private struct POINT { public int x, y; }
    [StructLayout(LayoutKind.Sequential)] private struct SIZE { public int cx, cy; }
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    private struct BLENDFUNCTION { public byte BlendOp, BlendFlags, SourceConstantAlpha, AlphaFormat; }

    [DllImport("user32.dll")] private static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] private static extern IntPtr GetDC(IntPtr hWnd);
    [DllImport("user32.dll")] private static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);
    [DllImport("gdi32.dll")] private static extern IntPtr CreateCompatibleDC(IntPtr hDC);
    [DllImport("gdi32.dll")] private static extern bool DeleteDC(IntPtr hdc);
    [DllImport("gdi32.dll")] private static extern IntPtr SelectObject(IntPtr hDC, IntPtr hObject);
    [DllImport("gdi32.dll")] private static extern bool DeleteObject(IntPtr hObject);
    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool UpdateLayeredWindow(IntPtr hwnd, IntPtr hdcDst, ref POINT pptDst, ref SIZE psize,
        IntPtr hdcSrc, ref POINT pptSrc, int crKey, ref BLENDFUNCTION pblend, int dwFlags);
}
