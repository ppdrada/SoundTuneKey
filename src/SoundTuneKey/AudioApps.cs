using System.Diagnostics;
using System.Runtime.InteropServices;
using NAudio.CoreAudioApi;

namespace SoundTuneKey;

/// <summary>Um app que tem pelo menos uma sessão de áudio no Windows.</summary>
/// IsMuted: o mudo do próprio Windows para o app (o volume fica guardado e volta ao tirar o mudo).
/// HasAudio false: o app está aberto mas ainda não abriu o som; o Windows só dá volume a ele depois disso.
public record AudioApp(string ProcessName, string DisplayName, float Volume, bool IsPlaying, bool IsMuted, bool HasAudio = true);

public static class AudioApps
{
    /// <summary>
    /// Lista os apps com sessão de áudio no dispositivo de saída padrão.
    /// Um mesmo app (ex.: Chrome) pode ter várias sessões; aqui elas viram uma linha só.
    /// </summary>
    /// <param name="withSilent">
    /// Inclui no fim, em ordem alfabética, os apps com janela aberta que ainda não abriram o som:
    /// dá para escolher antes, e o controle começa a valer quando ele tocar.
    /// </param>
    public static List<AudioApp> List(bool withSilent = false)
    {
        var apps = AudioSessions();
        if (!withSilent)
            return apps;

        var names = new HashSet<string>(apps.Select(a => a.ProcessName), StringComparer.OrdinalIgnoreCase);
        var silent = new List<AudioApp>();
        foreach (var process in Process.GetProcesses())
        {
            try
            {
                if (process.MainWindowHandle == IntPtr.Zero || process.MainWindowTitle.Length == 0 ||
                    process.Id == Environment.ProcessId || NotApps.Contains(process.ProcessName) || !names.Add(process.ProcessName))
                    continue;
                silent.Add(new AudioApp(process.ProcessName, FriendlyName(process), 0f, false, false, HasAudio: false));
            }
            catch (InvalidOperationException) { } // fechou no meio da leitura
        }

        return [.. apps, .. silent.OrderBy(a => a.DisplayName)];
    }

    // janelas do próprio Windows e terminais, que não tocam som
    private static readonly HashSet<string> NotApps = new(StringComparer.OrdinalIgnoreCase)
    {
        "explorer", "ApplicationFrameHost", "TextInputHost", "SystemSettings", "ShellExperienceHost",
        "SearchHost", "StartMenuExperienceHost", "LockApp", "Taskmgr",
        // terminais: janelas de texto, não tocam som
        "WindowsTerminal", "OpenConsole", "conhost", "cmd", "powershell", "pwsh", "powershell_ise",
    };

    private static List<AudioApp> AudioSessions()
    {
        var apps = new Dictionary<string, AudioApp>(StringComparer.OrdinalIgnoreCase);
        try
        {
            using var enumerator = new MMDeviceEnumerator();
            using var device = enumerator.GetDefaultAudioEndpoint(DataFlow.Render, Role.Multimedia);
            var sessions = device.AudioSessionManager.Sessions;

            for (int i = 0; i < sessions.Count; i++)
            {
                try
                {
                    var session = sessions[i];
                    if (session.IsSystemSoundsSession)
                        continue;

                    var process = TryGetProcess((int)session.GetProcessID);
                    if (process is null)
                        continue;

                    var name = process.ProcessName;
                    bool playing = session.State == NAudio.CoreAudioApi.Interfaces.AudioSessionState.AudioSessionStateActive;
                    float volume = session.SimpleAudioVolume.Volume;
                    bool muted = session.SimpleAudioVolume.Mute;

                    if (apps.TryGetValue(name, out var existing))
                    {
                        apps[name] = existing with
                        {
                            IsPlaying = existing.IsPlaying || playing,
                            Volume = Math.Max(existing.Volume, volume),
                            IsMuted = existing.IsMuted && muted, // mudo só se todas as sessões estão mudas
                        };
                    }
                    else
                    {
                        apps[name] = new AudioApp(name, FriendlyName(process), volume, playing, muted);
                    }
                }
                // o app fechou ou a sessão sumiu (troca de saída de som) no meio da leitura: segue com as outras
                catch (Exception ex) when (ex is InvalidOperationException or COMException) { }
            }
        }
        catch (COMException) { } // sem saída de som (fone desconectado, acesso remoto): lista vazia

        return apps.Values.OrderByDescending(a => a.IsPlaying).ThenBy(a => a.DisplayName).ToList();
    }

    /// <summary>
    /// Volume e mudo atuais do app no Windows (podem ter mudado no Mixer), ou null se ele não tem mais áudio.
    /// Lê só as sessões dele, sem o nome amigável: roda a cada repetição do atalho.
    /// </summary>
    public static (float Volume, bool IsMuted)? Find(string processName)
    {
        float volume = 0f;
        bool muted = true;
        // mesma regra da lista: o maior volume, e mudo só se todas as sessões estão mudas
        bool found = ForEachSession(processName, session =>
        {
            volume = Math.Max(volume, session.SimpleAudioVolume.Volume);
            muted &= session.SimpleAudioVolume.Mute;
        });
        return found ? (volume, muted) : null;
    }

    /// <summary>
    /// Define o volume (0 a 1) de todas as sessões do app. O volume geral do Windows não muda.
    /// Retorna false se o app não tem mais nenhuma sessão de áudio.
    /// </summary>
    public static bool SetVolume(string processName, float volume)
    {
        volume = Math.Clamp(volume, 0f, 1f);
        return ForEachSession(processName, session => session.SimpleAudioVolume.Volume = volume);
    }

    /// <summary>Liga ou desliga o mudo de todas as sessões do app. Retorna false se o app não tem mais áudio.</summary>
    public static bool SetMute(string processName, bool muted) =>
        ForEachSession(processName, session => session.SimpleAudioVolume.Mute = muted);

    private static bool ForEachSession(string processName, Action<AudioSessionControl> action)
    {
        bool found = false;
        try
        {
            using var enumerator = new MMDeviceEnumerator();
            using var device = enumerator.GetDefaultAudioEndpoint(DataFlow.Render, Role.Multimedia);
            var sessions = device.AudioSessionManager.Sessions;

            for (int i = 0; i < sessions.Count; i++)
            {
                try
                {
                    var session = sessions[i];
                    if (session.IsSystemSoundsSession)
                        continue;

                    var process = TryGetProcess((int)session.GetProcessID);
                    if (process is null || !process.ProcessName.Equals(processName, StringComparison.OrdinalIgnoreCase))
                        continue;

                    action(session);
                    found = true;
                }
                // o app fechou ou a sessão sumiu no meio: segue com as outras sessões do app
                catch (Exception ex) when (ex is InvalidOperationException or COMException) { }
            }
        }
        catch (COMException) { } // sem saída de som: nada a mudar

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
                return ShortName(description);
        }
        catch (System.ComponentModel.Win32Exception) { }

        return process.ProcessName;
    }

    // nome comprido fica só com as duas primeiras palavras: "Visual Studio Code" → "Visual Studio"
    private static string ShortName(string name)
    {
        var words = name.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        return words.Length <= 2 ? name.Trim() : $"{words[0]} {words[1]}";
    }
}
