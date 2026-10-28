using System.Drawing.Drawing2D;

namespace SoundTuneKey;

/// <summary>
/// Slider no tema escuro: trilha clara até o valor atual e apagada depois, com uma bolinha para
/// segurar e arrastar. Clicar na trilha e as setas do teclado também funcionam. Usado no volume
/// e, mais fino, no tempo da música.
/// </summary>
public class VolumeBar : Control
{
    [System.ComponentModel.DefaultValue(6)]
    public int TrackHeight { get; init; } = 6;
    [System.ComponentModel.DefaultValue(18)]
    public int ThumbSize { get; init; } = 18;
    [System.ComponentModel.DefaultValue(5)]
    public int KeyStep { get; init; } = 5;

    private int _value;

    public int Minimum => 0;
    private int _maximum = 100;

    [System.ComponentModel.DefaultValue(100)]
    public int Maximum
    {
        get => _maximum;
        set
        {
            _maximum = Math.Max(1, value);
            _value = Math.Min(_value, _maximum);
            Invalidate();
        }
    }

    /// <summary>True enquanto o botão do mouse está segurando a barra.</summary>
    public bool IsDragging { get; private set; }

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

    /// <summary>Disparado quando o usuário solta o mouse depois de clicar ou arrastar.</summary>
    public event EventHandler? Released;

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
        float thumbSize = ThumbSize * Theme.Scale(this), trackHeight = TrackHeight * Theme.Scale(this);
        float left = thumbSize / 2f;
        float width = Width - thumbSize;
        float centerY = Height / 2f;
        float thumbX = left + width * _value / _maximum;

        var track = new RectangleF(left, centerY - trackHeight / 2f, width, trackHeight);
        using (var rest = new SolidBrush(Enabled ? Theme.Inactive : Theme.Border))
        using (var restPath = Rounded(track, trackHeight / 2f))
            g.FillPath(rest, restPath);

        if (Enabled && thumbX > left)
        {
            var filled = track with { Width = thumbX - left };
            using var fill = new SolidBrush(Theme.Text);
            using var fillPath = Rounded(filled, Math.Min(trackHeight / 2f, filled.Width / 2));
            g.FillPath(fill, fillPath);
        }

        using var thumb = new SolidBrush(Enabled ? Theme.Text : Theme.Inactive);
        g.FillEllipse(thumb, thumbX - thumbSize / 2f, centerY - thumbSize / 2f, thumbSize, thumbSize);

        if (Focused)
            ControlPaint.DrawFocusRectangle(g, ClientRectangle, Theme.Text, Theme.Background);
    }

    protected override void OnMouseDown(MouseEventArgs e)
    {
        base.OnMouseDown(e);
        Focus();
        IsDragging = true;
        SetFromMouse(e.X);
    }

    protected override void OnMouseMove(MouseEventArgs e)
    {
        base.OnMouseMove(e);
        if (e.Button == MouseButtons.Left)
            SetFromMouse(e.X);
    }

    protected override void OnMouseUp(MouseEventArgs e)
    {
        base.OnMouseUp(e);
        if (!IsDragging)
            return;
        IsDragging = false;
        Released?.Invoke(this, EventArgs.Empty);
    }

    protected override bool IsInputKey(Keys keyData) =>
        keyData is Keys.Left or Keys.Right or Keys.Up or Keys.Down || base.IsInputKey(keyData);

    protected override void OnKeyDown(KeyEventArgs e)
    {
        base.OnKeyDown(e);
        int step = e.KeyCode switch
        {
            Keys.Right or Keys.Up => KeyStep,
            Keys.Left or Keys.Down => -KeyStep,
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
        float thumbSize = ThumbSize * Theme.Scale(this);
        float fraction = (x - thumbSize / 2f) / (Width - thumbSize);
        SetByUser((int)Math.Round(Math.Clamp(fraction, 0f, 1f) * _maximum));
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
