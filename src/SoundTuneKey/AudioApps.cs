using System.Diagnostics;
using NAudio.CoreAudioApi;

namespace SoundTuneKey;

/// <summary>Um app que tem pelo menos uma sessão de áudio no Windows.</summary>
public record AudioApp(string ProcessName, string DisplayName, float Volume, bool IsPlaying);

public static class AudioApps
{
    /// <summary>
    /// Lista os apps com sessão de áudio no dispositivo de saída padrão.
    /// Um mesmo app (ex.: Chrome) pode ter várias sessões; aqui elas viram uma linha só.
    /// </summary>
    public static List<AudioApp> List()
    {
        using var enumerator = new MMDeviceEnumerator();
        using var device = enumerator.GetDefaultAudioEndpoint(DataFlow.Render, Role.Multimedia);
        var sessions = device.AudioSessionManager.Sessions;

        var apps = new Dictionary<string, AudioApp>(StringComparer.OrdinalIgnoreCase);
        for (int i = 0; i < sessions.Count; i++)
        {
            var session = sessions[i];
            if (session.IsSystemSoundsSession)
                continue;

            var process = TryGetProcess((int)session.GetProcessID);
            if (process is null)
                continue;

            bool playing = session.State == NAudio.CoreAudioApi.Interfaces.AudioSessionState.AudioSessionStateActive;
            float volume = session.SimpleAudioVolume.Volume;

            if (apps.TryGetValue(process.ProcessName, out var existing))
            {
                apps[process.ProcessName] = existing with
                {
                    IsPlaying = existing.IsPlaying || playing,
                    Volume = Math.Max(existing.Volume, volume),
                };
            }
            else
            {
                apps[process.ProcessName] = new AudioApp(process.ProcessName, FriendlyName(process), volume, playing);
            }
        }

        return apps.Values.OrderByDescending(a => a.IsPlaying).ThenBy(a => a.DisplayName).ToList();
    }

    /// <summary>
    /// Define o volume (0 a 1) de todas as sessões do app. O volume geral do Windows não muda.
    /// Retorna false se o app não tem mais nenhuma sessão de áudio.
    /// </summary>
    public static bool SetVolume(string processName, float volume)
    {
        volume = Math.Clamp(volume, 0f, 1f);

        using var enumerator = new MMDeviceEnumerator();
        using var device = enumerator.GetDefaultAudioEndpoint(DataFlow.Render, Role.Multimedia);
        var sessions = device.AudioSessionManager.Sessions;

        bool found = false;
        for (int i = 0; i < sessions.Count; i++)
        {
            var session = sessions[i];
            if (session.IsSystemSoundsSession)
                continue;

            var process = TryGetProcess((int)session.GetProcessID);
            if (process is null || !process.ProcessName.Equals(processName, StringComparison.OrdinalIgnoreCase))
                continue;

            session.SimpleAudioVolume.Volume = volume;
            found = true;
        }

        return found;
    }

    private static Process? TryGetProcess(int pid)
    {
        try { return Process.GetProcessById(pid); }
        catch (ArgumentException) { return null; } // o processo já fechou
    }

    // Usa a descrição do executável ("Spotify", "Google Chrome") quando der;
    // processos protegidos não deixam ler isso, então cai no nome do processo.
    private static string FriendlyName(Process process)
    {
        try
        {
            var description = process.MainModule?.FileVersionInfo.FileDescription;
            if (!string.IsNullOrWhiteSpace(description))
                return description;
        }
        catch (System.ComponentModel.Win32Exception) { }

        return process.ProcessName;
    }
}
