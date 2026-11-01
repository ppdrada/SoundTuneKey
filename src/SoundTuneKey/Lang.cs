using System.Globalization;

namespace SoundTuneKey;

/// <summary>
/// Idioma do app: português, inglês ou espanhol, escolhido no "Sobre". Cada texto fica no próprio lugar
/// onde é usado, nas três línguas: <c>Lang.T("Sair", "Exit", "Salir")</c>. Ao trocar, <see cref="Changed"/>
/// avisa as telas abertas para escreverem tudo de novo (vale na hora, sem reabrir o app).
/// </summary>
public static class Lang
{
    /// <summary>"pt", "en" ou "es"; é o que fica salvo nas preferências.</summary>
    public static string Code { get; private set; } = "pt";

    public static event Action? Changed;

    public static string T(string portuguese, string english, string spanish) => Code switch
    {
        "en" => english,
        "es" => spanish,
        _ => portuguese,
    };

    /// <param name="saved">"pt", "en" ou "es" salvo nas preferências; sem nada, segue o idioma do Windows</param>
    public static void Load(string? saved) =>
        Code = saved is "pt" or "en" or "es" ? saved : CultureInfo.CurrentUICulture.TwoLetterISOLanguageName switch
        {
            "pt" => "pt",
            "es" => "es",
            _ => "en",
        };

    /// <param name="code">"pt", "en" ou "es"</param>
    public static void Set(string code)
    {
        if (Code == code)
            return;
        Code = code;
        Changed?.Invoke();
    }
}
