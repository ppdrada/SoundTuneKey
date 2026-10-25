namespace SoundTuneKey;

/// <summary>Ícone do app (assets/icon/icon.ico), embutido no .exe.</summary>
public static class AppIcon
{
    public static Icon Load()
    {
        using var stream = typeof(AppIcon).Assembly.GetManifestResourceStream("SoundTuneKey.icon.ico")
            ?? throw new InvalidOperationException("Ícone SoundTuneKey.icon.ico não foi embutido no .exe.");
        return new Icon(stream);
    }
}
