using System.Runtime.InteropServices;

namespace SoundTuneKey;

static class Program
{
    /// <summary>Mensagem que a segunda cópia manda para a primeira: "mostre a janela".</summary>
    public static readonly int ShowRunningMessage = RegisterWindowMessage("SoundTuneKey.ShowWindow");

    [STAThread]
    static void Main(string[] args)
    {
        ApplicationConfiguration.Initialize();

        // depois de se atualizar sozinho: espera o .exe antigo fechar e apaga a cópia dele
        bool justUpdated = Updates.FinishUpdate(args);

        // uma cópia só: duas brigariam pelos atalhos e mostrariam dois ícones na bandeja
        using var single = new Mutex(false, @"Local\SoundTuneKey");
        if (!Own(single, justUpdated))
        {
            // já aberto (ex.: pelo "Iniciar com o Windows"): mostra a janela dele e sai
            AllowSetForegroundWindow(ASFW_ANY);
            PostMessage(HWND_BROADCAST, ShowRunningMessage, 0, 0);
            return;
        }

        bool startHidden = args.Contains(WindowsStartup.TrayArgument);
        Application.Run(new MainForm(startHidden, justUpdated));
    }

    // depois de atualizar, o .exe antigo pode demorar um pouco a fechar e soltar a trava
    private static bool Own(Mutex mutex, bool justUpdated)
    {
        try { return mutex.WaitOne(justUpdated ? TimeSpan.FromSeconds(5) : TimeSpan.Zero); }
        catch (AbandonedMutexException) { return true; } // a cópia anterior fechou sem soltar: a trava é nossa
    }

    private static readonly IntPtr HWND_BROADCAST = 0xFFFF;
    private const int ASFW_ANY = -1;

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int RegisterWindowMessage(string message);

    [DllImport("user32.dll")]
    private static extern bool PostMessage(IntPtr hWnd, int msg, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern bool AllowSetForegroundWindow(int processId);
}
