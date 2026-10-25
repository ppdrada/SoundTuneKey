using System.Drawing.Drawing2D;

namespace SoundTuneKey;

/// <summary>
/// Slider de volume no tema escuro: trilha clara até o volume atual e apagada depois, com uma
/// bolinha para segurar e arrastar. Clicar na trilha e as setas do teclado também funcionam.
/// </summary>
public class VolumeBar : Control
{
    private const int TrackHeight = 6;
    private const int ThumbSize = 18;

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

        // a trilha começa e termina meia bolinha para dentro, para a bolinha caber nas pontas
        float left = ThumbSize / 2f;
        float width = Width - ThumbSize;
        float centerY = Height / 2f;
        float thumbX = left + width * _value / 100f;

        var track = new RectangleF(left, centerY - TrackHeight / 2f, width, TrackHeight);
        using (var rest = new SolidBrush(Enabled ? Theme.Inactive : Theme.Border))
        using (var restPath = Rounded(track, TrackHeight / 2f))
            g.FillPath(rest, restPath);

        if (Enabled && thumbX > left)
        {
            var filled = track with { Width = thumbX - left };
            using var fill = new SolidBrush(Theme.Text);
            using var fillPath = Rounded(filled, Math.Min(TrackHeight / 2f, filled.Width / 2));
            g.FillPath(fill, fillPath);
        }

        using var thumb = new SolidBrush(Enabled ? Theme.Text : Theme.Inactive);
        g.FillEllipse(thumb, thumbX - ThumbSize / 2f, centerY - ThumbSize / 2f, ThumbSize, ThumbSize);

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

    private void SetFromMouse(int x)
    {
        float fraction = (x - ThumbSize / 2f) / (Width - ThumbSize);
        SetByUser((int)Math.Round(Math.Clamp(fraction, 0f, 1f) * 100));
    }

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
