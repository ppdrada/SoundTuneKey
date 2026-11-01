namespace SoundTuneKey;

/// <summary>
/// "Atalhos": janelinha no mesmo estilo do "Sobre" (sem barra de título, cantos arredondados),
/// aberta pelo rodapé da janela e pelo menu da bandeja.
/// </summary>
public class ShortcutsWindow : Form
{
    // montada a cada abertura, no idioma escolhido
    private static (string Keys, string Action)[] Shortcuts =>
    [
        ("Ctrl + Alt + ↑", Lang.T("Aumenta o volume", "Volume up", "Subir volumen")),
        ("Ctrl + Alt + ↓", Lang.T("Diminui o volume", "Volume down", "Bajar volumen")),
        ("Ctrl + Alt + P", Lang.T("Pausar / continuar", "Play / pause", "Reproducir / pausar")),
        ("Ctrl + Alt + →", Lang.T("Próxima música", "Next track", "Siguiente canción")),
        ("Ctrl + Alt + ←", Lang.T("Volta ao começo (2x rápido: música anterior)", "Back to start (twice quickly: previous track)", "Volver al inicio (2 veces rápido: canción anterior)")),
        ("Ctrl + Alt + M", Lang.T("Mudo / volta o som", "Mute / unmute", "Silenciar / activar sonido")),
        ("Ctrl + Alt + A", Lang.T("Troca o app controlado (o próximo da lista)", "Switch the controlled app (next in the list)", "Cambiar la app controlada (la siguiente de la lista)")),
        ("Ctrl + Alt + V", Lang.T("Liga / desliga o microfone (o padrão do Windows)", "Microphone on / off (the Windows default one)", "Activa / desactiva el micrófono (el predeterminado de Windows)")),
    ];

    public ShortcutsWindow()
    {
        SuspendLayout();
        AutoScaleDimensions = new SizeF(96f, 96f);
        AutoScaleMode = AutoScaleMode.Dpi;

        Text = Lang.T("Sound Tune Key — Atalhos", "Sound Tune Key — Shortcuts", "Sound Tune Key — Atajos");
        FormBorderStyle = FormBorderStyle.None;
        StartPosition = FormStartPosition.CenterScreen;
        ClientSize = new Size(440, 112 + Shortcuts.Length * 28);
        BackColor = Theme.Background;
        ForeColor = Theme.Text;
        Icon = AppIcon.Load();
        KeyPreview = true;
        HandleCreated += (_, _) => Theme.UseRoundCorners(this);

        var title = new Label
        {
            Dock = DockStyle.Top,
            Height = 30,
            Text = Lang.T("Atalhos", "Shortcuts", "Atajos"),
            TextAlign = ContentAlignment.BottomCenter,
            Font = new Font(Font.FontFamily, 13f, FontStyle.Bold),
        };
        var subtitle = new Label
        {
            Dock = DockStyle.Top,
            Height = 26,
            Text = Lang.T("Funcionam com qualquer janela na frente, inclusive jogos", "They work with any window in front, even games", "Funcionan con cualquier ventana al frente, incluso juegos"),
            TextAlign = ContentAlignment.MiddleCenter,
            ForeColor = Theme.MutedText,
        };

        var table = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 2, Padding = new Padding(24, 6, 16, 0) };
        table.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 120));
        table.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        foreach (var (keys, action) in Shortcuts)
        {
            table.Controls.Add(new Label { Text = keys, AutoSize = true, Font = new Font(Font, FontStyle.Bold), Margin = new Padding(0, 0, 0, 7) });
            table.Controls.Add(new Label { Text = action, AutoSize = true, ForeColor = Theme.MutedText, Margin = new Padding(0, 0, 0, 7) });
        }

        var close = new Button { Text = Lang.T("Fechar", "Close", "Cerrar"), Width = 100, Height = 32, Cursor = Cursors.Hand };
        Theme.Apply(close);
        close.Click += (_, _) => Close();
        var buttons = new FlowLayoutPanel { Dock = DockStyle.Bottom, Height = 52, FlowDirection = FlowDirection.RightToLeft, Padding = new Padding(0, 0, 24, 0) };
        buttons.Controls.Add(close);

        Controls.Add(table);
        Controls.Add(subtitle);
        Controls.Add(title);
        Controls.Add(buttons);
        ResumeLayout(false);

        AcceptButton = close;
        KeyDown += (_, e) => { if (e.KeyCode == Keys.Escape) Close(); };
    }
}
