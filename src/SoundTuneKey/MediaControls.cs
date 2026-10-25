using Windows.Media.Control;

namespace SoundTuneKey;

public enum MediaCommand { PlayPause, Next, Previous, Restart }

/// <summary>
/// Controles de mídia do Windows (os mesmos das teclas de mídia), direcionados a um app específico.
/// Só funcionam com apps que expõem esses controles ao Windows (Spotify, abas do Chrome...).
/// </summary>
public static class MediaControls
{
    private static GlobalSystemMediaTransportControlsSessionManager? _manager;

    /// <summary>
    /// Envia o comando para a sessão de mídia do app. Retorna false se o app não tem controles de mídia.
    /// </summary>
    public static async Task<bool> SendAsync(string processName, MediaCommand command)
    {
        var session = await FindSessionAsync(processName);
        if (session is null)
            return false;

        return command switch
        {
            MediaCommand.PlayPause => await session.TryTogglePlayPauseAsync(),
            MediaCommand.Next => await session.TrySkipNextAsync(),
            MediaCommand.Previous => await session.TrySkipPreviousAsync(),
            // volta para o começo da música; se o app não deixa mudar a posição, volta a música mesmo
            MediaCommand.Restart => await session.TryChangePlaybackPositionAsync(0) || await session.TrySkipPreviousAsync(),
            _ => false,
        };
    }

    // O Windows identifica a sessão pelo AppUserModelId ("Spotify.exe", "Chrome",
    // "SpotifyAB.SpotifyMusic_...!Spotify"), que contém o nome do processo.
    private static async Task<GlobalSystemMediaTransportControlsSession?> FindSessionAsync(string processName)
    {
        _manager ??= await GlobalSystemMediaTransportControlsSessionManager.RequestAsync();

        return _manager.GetSessions()
            .FirstOrDefault(s => s.SourceAppUserModelId.Contains(processName, StringComparison.OrdinalIgnoreCase));
    }
}
