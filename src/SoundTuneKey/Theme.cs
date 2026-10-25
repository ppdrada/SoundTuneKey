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

    [DllImport("dwmapi.dll")]
    private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attribute, ref int value, int size);

    [DllImport("user32.dll")]
    private static extern IntPtr SendMessage(IntPtr hWnd, int msg, IntPtr wParam, IntPtr lParam);

    [DllImport("uxtheme.dll", CharSet = CharSet.Unicode)]
    private static extern int SetWindowTheme(IntPtr hwnd, string? appName, string? idList);

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

    /// <summary>Menu da bandeja escuro.</summary>
    public static void Apply(ToolStrip menu)
    {
        menu.Renderer = new DarkMenuRenderer();
        menu.BackColor = Raised;
        menu.ForeColor = Text;
    }

    // Texto, setinha do submenu e ✓ claros; o renderer padrão desenha esses detalhes em preto.
    private sealed class DarkMenuRenderer() : ToolStripProfessionalRenderer(new DarkMenuColors())
    {
        protected override void OnRenderItemText(ToolStripItemTextRenderEventArgs e)
        {
            e.TextColor = e.Item.Enabled ? Text : MutedText;
            base.OnRenderItemText(e);
        }

        protected override void OnRenderArrow(ToolStripArrowRenderEventArgs e)
        {
            e.ArrowColor = Text;
            base.OnRenderArrow(e);
        }

        protected override void OnRenderItemCheck(ToolStripItemImageRenderEventArgs e)
        {
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
