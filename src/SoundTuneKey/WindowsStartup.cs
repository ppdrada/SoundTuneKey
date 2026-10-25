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
        if (IsEnabled)
            SetEnabled(true);
    }

    private static string Command()
    {
        var exe = Environment.ProcessPath!;

        // no Debug o programa roda como "dotnet SoundTuneKey.dll" (veja o .csproj)
        if (Path.GetFileName(exe).Equals("dotnet.exe", StringComparison.OrdinalIgnoreCase))
            return $"\"{exe}\" \"{typeof(WindowsStartup).Assembly.Location}\" {TrayArgument}";

        return $"\"{exe}\" {TrayArgument}";
    }
}
