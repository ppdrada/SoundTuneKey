using System.Text.Json;

namespace SoundTuneKey;

/// <summary>Preferências salvas em %AppData%\SoundTuneKey\settings.json.</summary>
public class AppSettings
{
    /// <summary>Nome do processo do último app escolhido (ex.: "Spotify").</summary>
    public string? LastApp { get; set; }

    /// <summary>Aviso na tela ao usar os atalhos de volume e mudo (dá para desligar no menu da bandeja).</summary>
    public bool ShowOsd { get; set; } = true;

    /// <summary>Última versão nova já avisada no balão (o balão aparece uma vez por versão).</summary>
    public string? NotifiedVersion { get; set; }

    private static readonly string FilePath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "SoundTuneKey", "settings.json");

    public static AppSettings Load()
    {
        try
        {
            if (File.Exists(FilePath))
                return JsonSerializer.Deserialize<AppSettings>(File.ReadAllText(FilePath)) ?? new();
        }
        catch (Exception ex) when (ex is IOException or JsonException or UnauthorizedAccessException)
        {
            // arquivo corrompido ou sem acesso: começa do zero em vez de não abrir
        }

        return new();
    }

    public void Save()
    {
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(FilePath)!);
            File.WriteAllText(FilePath, JsonSerializer.Serialize(this));
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            // não conseguir salvar a preferência não deve atrapalhar o uso
        }
    }
}
