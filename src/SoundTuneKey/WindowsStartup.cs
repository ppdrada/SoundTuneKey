using Microsoft.Win32;

namespace SoundTuneKey;

/// <summary>
/// "Iniciar com o Windows": uma entrada em HKCU\...\Run, só para o usuário atual (não precisa de administrador).
/// </summary>
public static class WindowsStartup
{
    public const string TrayArgument = "--tray"; // abre direto na bandeja, sem mostrar a janela

    private const string RunKey = @"Software\Microsoft\Windows\CurrentVersion\Run";
    private const string ValueName = "SoundTuneKey";

    public static bool IsEnabled
    {
        get
        {
            using var key = Registry.CurrentUser.OpenSubKey(RunKey);
            return key?.GetValue(ValueName) is string;
        }
    }

    public static void SetEnabled(bool enabled)
    {
        using var key = Registry.CurrentUser.CreateSubKey(RunKey);
        if (enabled)
            key.SetValue(ValueName, Command());
        else
            key.DeleteValue(ValueName, throwOnMissingValue: false);
    }

    /// <summary>Se a pessoa moveu o .exe de pasta, atualiza o caminho salvo.</summary>
    public static void RefreshPath()
    {
        // a versão de teste (Debug) não toma o lugar do .exe de verdade: senão o Windows passa a
        // abrir o "dotnet" ao ligar, e o Gerenciador de Tarefas perde o fornecedor "ppdrada"
        if (IsEnabled && !RunningFromDotnet)
            SetEnabled(true);
    }

    // no Debug o programa roda como "dotnet SoundTuneKey.dll" (veja o .csproj)
    private static bool RunningFromDotnet =>
        Path.GetFileName(Environment.ProcessPath!).Equals("dotnet.exe", StringComparison.OrdinalIgnoreCase);

    private static string Command()
    {
        var exe = Environment.ProcessPath!;

        if (RunningFromDotnet)
        {
            var dll = Path.Combine(AppContext.BaseDirectory, typeof(WindowsStartup).Assembly.GetName().Name + ".dll");
            return $"\"{exe}\" \"{dll}\" {TrayArgument}";
        }

        return $"\"{exe}\" {TrayArgument}";
    }
}
