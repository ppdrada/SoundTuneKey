using System.Drawing.Drawing2D;

namespace SoundTuneKey;

/// <summary>
/// Barra de volume no estilo do ícone: barrinhas que vão crescendo, claras até o volume atual
/// e apagadas depois. Clique ou arraste para mudar; setas do teclado também funcionam.
/// </summary>
public class VolumeBar : Control
{
    private const int Bars = 20;
    private const int Gap = 4;

    private int _value;

    public int Minimum => 0;
    public int Maximum => 100;

    [System.ComponentModel.DefaultValue(0)]
    public int Value
    {
        get => _value;
        set
        {
            value = Math.Clamp(value, Minimum, Maximum);
            if (value == _value)
                return;
            _value = value;
            Invalidate();
        }
    }

    /// <summary>Disparado só quando o usuário muda o volume (mouse ou teclado).</summary>
    public event EventHandler? Scroll;

    public VolumeBar()
    {
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer |
                 ControlStyles.UserPaint | ControlStyles.ResizeRedraw | ControlStyles.Selectable, true);
        BackColor = Theme.Background;
        Cursor = Cursors.Hand;
        TabStop = true;
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;

        float barWidth = (Width - Gap * (Bars - 1)) / (float)Bars;
        int lit = (int)Math.Round(_value / 100f * Bars);

        for (int i = 0; i < Bars; i++)
        {
            // altura cresce da esquerda para a direita, como no ícone
            float height = Height * (0.3f + 0.7f * (i + 1) / Bars);
            var rect = new RectangleF(i * (barWidth + Gap), Height - height, barWidth, height);

            var color = !Enabled ? Theme.Border : i < lit ? Theme.Text : Theme.Inactive;
            using var brush = new SolidBrush(color);
            using var path = Rounded(rect, Math.Min(3f, barWidth / 2));
            g.FillPath(brush, path);
        }

        if (Focused)
            ControlPaint.DrawFocusRectangle(g, ClientRectangle, Theme.Text, Theme.Background);
    }

    protected override void OnMouseDown(MouseEventArgs e)
    {
        base.OnMouseDown(e);
        Focus();
        SetFromMouse(e.X);
    }

    protected override void OnMouseMove(MouseEventArgs e)
    {
        base.OnMouseMove(e);
        if (e.Button == MouseButtons.Left)
            SetFromMouse(e.X);
    }

    protected override bool IsInputKey(Keys keyData) =>
        keyData is Keys.Left or Keys.Right or Keys.Up or Keys.Down || base.IsInputKey(keyData);

    protected override void OnKeyDown(KeyEventArgs e)
    {
        base.OnKeyDown(e);
        int step = e.KeyCode switch
        {
            Keys.Right or Keys.Up => 5,
            Keys.Left or Keys.Down => -5,
            _ => 0,
        };
        if (step != 0)
            SetByUser(_value + step);
    }

    protected override void OnEnabledChanged(EventArgs e)
    {
        base.OnEnabledChanged(e);
        Invalidate();
    }

    protected override void OnGotFocus(EventArgs e) { base.OnGotFocus(e); Invalidate(); }
    protected override void OnLostFocus(EventArgs e) { base.OnLostFocus(e); Invalidate(); }

    private void SetFromMouse(int x) => SetByUser((int)Math.Round(Math.Clamp(x / (float)Width, 0f, 1f) * 100));

    private void SetByUser(int value)
    {
        int before = _value;
        Value = value;
        if (_value != before)
            Scroll?.Invoke(this, EventArgs.Empty);
    }

    private static GraphicsPath Rounded(RectangleF r, float radius)
    {
        var path = new GraphicsPath();
        float d = radius * 2;
        path.AddArc(r.X, r.Y, d, d, 180, 90);
        path.AddArc(r.Right - d, r.Y, d, d, 270, 90);
        path.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
        path.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
        path.CloseFigure();
        return path;
    }
}
