using System.Globalization;

namespace SoundTuneKey;

/// <summary>
/// Idioma do app: português ou inglês, escolhido no "Sobre". Cada texto fica no próprio lugar onde
/// é usado, nas duas línguas: <c>Lang.T("Sair", "Exit")</c>. Ao trocar, <see cref="Changed"/> avisa as
/// telas abertas para escreverem tudo de novo (vale na hora, sem reabrir o app).
/// </summary>
public static class Lang
{
    public static bool English { get; private set; }

    public static event Action? Changed;

    public static string T(string portuguese, string english) => English ? english : portuguese;

    /// <param name="saved">"pt" ou "en" salvo nas preferências; sem nada, segue o idioma do Windows</param>
    public static void Load(string? saved) =>
        English = saved is null ? CultureInfo.CurrentUICulture.TwoLetterISOLanguageName != "pt" : saved == "en";

    public static string Code => English ? "en" : "pt";

    public static void Set(bool english)
    {
        if (English == english)
            return;
        English = english;
        Changed?.Invoke();
    }
}
