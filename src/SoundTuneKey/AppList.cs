namespace SoundTuneKey;

/// <summary>
/// Lista de apps em que o botão direito só abre o menu (mudo etc.) e não seleciona a linha:
/// selecionar troca o app controlado, e isso não pode acontecer só por abrir o menu.
/// </summary>
public class AppList : ListView
{
    private const int WM_RBUTTONDOWN = 0x0204;
    private const int WM_RBUTTONUP = 0x0205;

    protected override void WndProc(ref Message m)
    {
        // a lista selecionaria a linha ao apertar; aqui só o menu abre, ao soltar o botão
        if (m.Msg == WM_RBUTTONDOWN)
            return;
        if (m.Msg == WM_RBUTTONUP)
        {
            ContextMenuStrip?.Show(Cursor.Position);
            return;
        }

        base.WndProc(ref m);

        // o tema escuro (barra de rolagem) desenha as linhas das colunas no espaço vazio embaixo do
        // último app; esse espaço recebe o fundo da lista
        const int WM_PAINT = 0x000F;
        if (m.Msg == WM_PAINT && View == View.Details)
        {
            int top = Items.Count > 0 ? GetItemRect(Items.Count - 1).Bottom : 0;
            if (top < ClientSize.Height)
            {
                using var g = CreateGraphics();
                using var back = new SolidBrush(BackColor);
                g.FillRectangle(back, 0, Math.Max(top, 0), ClientSize.Width, ClientSize.Height - Math.Max(top, 0));
            }
        }
    }
}
