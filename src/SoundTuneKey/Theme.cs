using System.Runtime.InteropServices;

namespace SoundTuneKey;

/// <summary>Tema escuro com as mesmas cores do ícone (assets/icon/icon.svg).</summary>
public static class Theme
{
    public static readonly Color Background = ColorTranslator.FromHtml("#1C1C1E"); // fundo do ícone
    public static readonly Color Surface = ColorTranslator.FromHtml("#242427");    // lista
    public static readonly Color Raised = ColorTranslator.FromHtml("#2C2C30");     // botões, cabeçalho
    public static readonly Color Border = ColorTranslator.FromHtml("#3A3A40");
    public static readonly Color Selection = ColorTranslator.FromHtml("#3A3A40");
    public static readonly Color Text = ColorTranslator.FromHtml("#F2F2F2");       // barras claras do ícone
    public static readonly Color MutedText = ColorTranslator.FromHtml("#9A9AA0");
    public static readonly Color Inactive = ColorTranslator.FromHtml("#4A4A50");   // barras apagadas do ícone

    /// <summary>Quanto a tela do controle está ampliada (1 = 100%, 1,25 = 125%).</summary>
    public static float Scale(Control control)
    {
        // dentro do menu da bandeja o Windows não informa a escala certa: o mini player guarda a dele
        for (var parent = control.Parent; parent is not null; parent = parent.Parent)
            if (parent is PlayerPanel { MenuScale: float menuScale })
                return menuScale;

        return control.DeviceDpi / 96f;
    }

    /// <summary>A mesma escala, mas do monitor onde está o ponto (ex.: onde o mouse clicou).</summary>
    public static float ScaleAt(Point point)
    {
        const uint MONITOR_DEFAULTTONEAREST = 2, MDT_EFFECTIVE_DPI = 0;
        var monitor = MonitorFromPoint(point, MONITOR_DEFAULTTONEAREST);
        return GetDpiForMonitor(monitor, MDT_EFFECTIVE_DPI, out uint dpi, out _) == 0 ? dpi / 96f : 1f;
    }

    [DllImport("user32.dll")]
    private static extern IntPtr MonitorFromPoint(Point point, uint flags);

    [DllImport("shcore.dll")]
    private static extern int GetDpiForMonitor(IntPtr monitor, uint type, out uint dpiX, out uint dpiY);

    [DllImport("dwmapi.dll")]
    private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attribute, ref int value, int size);

    [DllImport("user32.dll")]
    private static extern IntPtr SendMessage(IntPtr hWnd, int msg, IntPtr wParam, IntPtr lParam);

    [DllImport("uxtheme.dll", CharSet = CharSet.Unicode)]
    private static extern int SetWindowTheme(IntPtr hwnd, string? appName, string? idList);

    /// <summary>Cantos arredondados do Windows 11 (menores nos menus); no Windows 10 ficam retos.</summary>
    public static void UseRoundCorners(Control window, bool small = false)
    {
        const int DWMWA_WINDOW_CORNER_PREFERENCE = 33, DWMWCP_ROUND = 2, DWMWCP_ROUNDSMALL = 3;
        int round = small ? DWMWCP_ROUNDSMALL : DWMWCP_ROUND;
        DwmSetWindowAttribute(window.Handle, DWMWA_WINDOW_CORNER_PREFERENCE, ref round, sizeof(int));
    }

    /// <summary>
    /// Ícone de menu com a fonte de ícones do próprio Windows (Segoe Fluent Icons no 11, MDL2 no 10),
    /// na cor do texto secundário. Ex.: '' abrir, '' lista, '' teclado.
    /// </summary>
    public static Bitmap MenuIcon(char glyph)
    {
        var bmp = new Bitmap(16, 16);
        using var g = Graphics.FromImage(bmp);
        // AntiAlias comum: o ClearType do TextRenderer, num fundo transparente, deixa um quadradinho escuro em volta
        g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.AntiAlias;
        using var font = new Font(IconFont, 11f, GraphicsUnit.Pixel);
        using var brush = new SolidBrush(MutedText);
        using var center = new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center };
        g.DrawString(glyph.ToString(), font, brush, new RectangleF(0, 0, 16, 16), center);
        return bmp;
    }

    // os ícones e as bolinhas do menu são desenhados um pouco para dentro, para não encostar na borda
    private const int MenuIconInset = 6;

    private static readonly string IconFont = FontFamily.Families.Any(f => f.Name == "Segoe Fluent Icons")
        ? "Segoe Fluent Icons" : "Segoe MDL2 Assets";

    /// <summary>Barra de título escura (Windows 10 20H1+ e Windows 11).</summary>
    public static void UseDarkTitleBar(Form form)
    {
        const int DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
        int on = 1;
        DwmSetWindowAttribute(form.Handle, DWMWA_USE_IMMERSIVE_DARK_MODE, ref on, sizeof(int));
    }

    /// <summary>
    /// Lista escura: cabeçalho e linhas desenhados aqui; a barra de rolagem usa o tema escuro do Windows.
    /// </summary>
    public static void Apply(ListView list)
    {
        list.BackColor = Surface;
        list.ForeColor = Text;
        list.BorderStyle = BorderStyle.None;
        list.OwnerDraw = true;
        list.HandleCreated += (_, _) =>
        {
            // ItemsView: barra de rolagem escura e sem linhas de coluna na área vazia;
            // no cabeçalho, pinta escuro o espaço depois da última coluna
            const int LVM_GETHEADER = 0x101F;
            SetWindowTheme(SendMessage(list.Handle, LVM_GETHEADER, 0, 0), "DarkMode_ItemsView", null);
        };

        list.DrawColumnHeader += (_, e) =>
        {
            using var back = new SolidBrush(Raised);
            e.Graphics.FillRectangle(back, e.Bounds);
            using var line = new Pen(Border);
            e.Graphics.DrawLine(line, e.Bounds.Left, e.Bounds.Bottom - 1, e.Bounds.Right, e.Bounds.Bottom - 1);

            var textBounds = Rectangle.Inflate(e.Bounds, -6, 0);
            TextRenderer.DrawText(e.Graphics, e.Header!.Text, list.Font, textBounds, MutedText,
                TextFormatFlags.VerticalCenter | TextFormatFlags.Left | TextFormatFlags.EndEllipsis);
        };

        list.DrawItem += (_, e) => e.DrawDefault = false;

        list.DrawSubItem += (_, e) =>
        {
            bool selected = e.Item!.Selected;
            using var back = new SolidBrush(selected ? Selection : Surface);
            e.Graphics.FillRectangle(back, e.Bounds);

            var textBounds = Rectangle.Inflate(e.Bounds, -6, 0);
            TextRenderer.DrawText(e.Graphics, e.SubItem!.Text, list.Font, textBounds, Text,
                TextFormatFlags.VerticalCenter | TextFormatFlags.Left | TextFormatFlags.EndEllipsis);
        };
    }

    public static void Apply(Button button)
    {
        button.FlatStyle = FlatStyle.Flat;
        button.BackColor = Raised;
        button.ForeColor = Text;
        button.FlatAppearance.BorderColor = Border;
        button.FlatAppearance.MouseOverBackColor = Selection;
        button.FlatAppearance.MouseDownBackColor = Inactive;
    }

    /// <summary>Tag de um item de menu que é liga/desliga: aparece com a bolinha à esquerda em vez de ✓.</summary>
    public const string DotTag = "dot";

    /// <summary>Item marcável do menu com a bolinha do "Iniciar com o Windows" (veja <see cref="DotTag"/>).</summary>
    public static void UseDot(ToolStripMenuItem item)
    {
        item.Tag = DotTag;
        // uma imagem vazia faz o menu chamar OnRenderItemImage também quando o item está desmarcado
        item.Image = new Bitmap(16, 16);
    }

    /// <summary>Menu da bandeja escuro, no estilo do Windows 11: cantos e destaque arredondados, linhas mais altas.</summary>
    public static void Apply(ToolStrip menu)
    {
        menu.Renderer = new DarkMenuRenderer();
        menu.BackColor = Raised;
        menu.ForeColor = Text;
        if (menu is ToolStripDropDown dropDown)
            dropDown.HandleCreated += (_, _) => UseRoundCorners(dropDown, small: true);

        foreach (ToolStripItem item in menu.Items)
            Space(item);
        menu.ItemAdded += (_, e) => Space(e.Item!);

        static void Space(ToolStripItem item)
        {
            if (item is ToolStripMenuItem)
                item.Padding = new Padding(item.Padding.Left, 4, item.Padding.Right, 4);
        }
    }

    // Texto, setinha do submenu e ✓ claros; o renderer padrão desenha esses detalhes em preto.
    private sealed class DarkMenuRenderer() : ToolStripProfessionalRenderer(new DarkMenuColors())
    {
        protected override void OnRenderItemText(ToolStripItemTextRenderEventArgs e)
        {
            e.TextColor = e.Item.Enabled ? Text : MutedText;
            base.OnRenderItemText(e);
        }

        protected override void OnRenderItemImage(ToolStripItemImageRenderEventArgs e)
        {
            if (e.Item is ToolStripMenuItem { Tag: DotTag } item)
            {
                float s = Scale(e.ToolStrip!), d = RoundCheck.Dot * s;
                var r = e.ImageRectangle;
                RoundCheck.DrawDot(e.Graphics, new RectangleF(r.X + MenuIconInset * s + (r.Width - d) / 2, r.Y + (r.Height - d) / 2, d, d), item.Checked, s);
                return;
            }

            if (e.Image is not null && e.Item is ToolStripMenuItem)
            {
                var r = e.ImageRectangle;
                r.Y = (e.Item.Height - r.Height) / 2; // centrado na linha, como o texto
                r.Offset((int)(MenuIconInset * Scale(e.ToolStrip!)), 0);
                e.Graphics.DrawImage(e.Image, r);
                return;
            }
            base.OnRenderItemImage(e);
        }

        // destaque do item sob o mouse: uma pílula com cantos arredondados, afastada das bordas
        protected override void OnRenderMenuItemBackground(ToolStripItemRenderEventArgs e)
        {
            if (!e.Item.Selected || !e.Item.Enabled || e.Item is ToolStripControlHost)
                return;

            float s = Scale(e.ToolStrip!);
            var r = new RectangleF(6 * s, 1, e.Item.Width - 12 * s, e.Item.Height - 2);
            using var path = new System.Drawing.Drawing2D.GraphicsPath();
            float d = 8 * s;
            path.AddArc(r.X, r.Y, d, d, 180, 90);
            path.AddArc(r.Right - d, r.Y, d, d, 270, 90);
            path.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
            path.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
            path.CloseFigure();
            var old = e.Graphics.SmoothingMode;
            e.Graphics.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
            using var brush = new SolidBrush(Selection);
            e.Graphics.FillPath(brush, path);
            e.Graphics.SmoothingMode = old;
        }

        protected override void OnRenderArrow(ToolStripArrowRenderEventArgs e)
        {
            e.ArrowColor = Text;
            base.OnRenderArrow(e);
        }

        protected override void OnRenderItemCheck(ToolStripItemImageRenderEventArgs e)
        {
            if (e.Item.Tag is DotTag)
                return; // a bolinha já mostra se está marcado

            TextRenderer.DrawText(e.Graphics, "✓", e.Item.Font, e.ImageRectangle, Text,
                TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter);
        }
    }

    private sealed class DarkMenuColors : ProfessionalColorTable
    {
        public override Color ToolStripDropDownBackground => Raised;
        public override Color ImageMarginGradientBegin => Raised;
        public override Color ImageMarginGradientMiddle => Raised;
        public override Color ImageMarginGradientEnd => Raised;
        public override Color MenuBorder => Border;
        public override Color MenuItemBorder => Selection;
        public override Color MenuItemSelected => Selection;
        public override Color MenuItemSelectedGradientBegin => Selection;
        public override Color MenuItemSelectedGradientEnd => Selection;
        public override Color MenuItemPressedGradientBegin => Selection;
        public override Color MenuItemPressedGradientEnd => Selection;
        public override Color SeparatorDark => Border;
        public override Color SeparatorLight => Border;
        public override Color CheckBackground => Inactive;
        public override Color CheckSelectedBackground => Inactive;
        public override Color CheckPressedBackground => Inactive;
    }
}
