using Windows.Media.Control;

namespace SoundTuneKey;

public enum MediaCommand { PlayPause, Next, Previous, Restart }

public record MediaTimeline(TimeSpan Position, TimeSpan Duration);

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

    /// <summary>
    /// Posição e duração da música do app, ou null se o app não informa o tempo ao Windows.
    /// </summary>
    public static async Task<MediaTimeline?> GetTimelineAsync(string processName)
    {
        var session = await FindSessionAsync(processName);
        if (session is null)
            return null;

        var timeline = session.GetTimelineProperties();
        var duration = timeline.EndTime - timeline.StartTime;
        if (duration <= TimeSpan.Zero)
            return null;

        // a posição vale para o momento em que o app a informou; tocando, ela já andou desde então
        var position = timeline.Position - timeline.StartTime;
        bool playing = session.GetPlaybackInfo().PlaybackStatus ==
                       GlobalSystemMediaTransportControlsSessionPlaybackStatus.Playing;
        if (playing && timeline.LastUpdatedTime > DateTimeOffset.MinValue)
            position += DateTimeOffset.Now - timeline.LastUpdatedTime;

        if (position < TimeSpan.Zero)
            position = TimeSpan.Zero;
        if (position > duration)
            position = duration;

        return new MediaTimeline(position, duration);
    }

    /// <summary>Pula para <paramref name="position"/> na música do app.</summary>
    public static async Task<bool> SeekAsync(string processName, TimeSpan position)
    {
        var session = await FindSessionAsync(processName);
        if (session is null)
            return false;

        var start = session.GetTimelineProperties().StartTime;
        return await session.TryChangePlaybackPositionAsync((start + position).Ticks);
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
