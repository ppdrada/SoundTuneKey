namespace SoundTuneKey;

static class Program
{
    [STAThread]
    static void Main(string[] args)
    {
        ApplicationConfiguration.Initialize();

        bool startHidden = args.Contains(WindowsStartup.TrayArgument);
        Application.Run(new MainForm(startHidden));
    }
}
