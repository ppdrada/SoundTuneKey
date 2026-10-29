namespace SoundTuneKey;

static class Program
{
    [STAThread]
    static void Main(string[] args)
    {
        ApplicationConfiguration.Initialize();

        // depois de se atualizar sozinho: espera o .exe antigo fechar e apaga a cópia dele
        bool justUpdated = Updates.FinishUpdate(args);

        bool startHidden = args.Contains(WindowsStartup.TrayArgument);
        Application.Run(new MainForm(startHidden, justUpdated));
    }
}
