using NAudio.CoreAudioApi;

namespace SoundTuneKey;

/// <summary>
/// Mudo do microfone do Windows inteiro (Ctrl+Alt+V): vale para Discord, jogo e qualquer outro
/// programa. Usa o mudo do próprio Windows, então aparece também nas configurações de som.
/// </summary>
public static class Microphone
{
    /// <summary>true = mudo, false = ligado, null = nenhum microfone no PC.</summary>
    public static bool? IsMuted()
    {
        try
        {
            using var enumerator = new MMDeviceEnumerator();
            using var mic = enumerator.GetDefaultAudioEndpoint(DataFlow.Capture, Role.Console);
            return mic.AudioEndpointVolume.Mute;
        }
        catch (Exception ex) when (ex is System.Runtime.InteropServices.COMException or InvalidOperationException)
        {
            return null; // sem microfone (ou desconectado agora)
        }
    }

    /// <summary>Liga ou desliga. Devolve o estado novo (true = mudo) ou null se não há microfone.</summary>
    public static bool? Toggle()
    {
        if (IsMuted() is not bool muted)
            return null;

        bool mute = !muted;
        using var enumerator = new MMDeviceEnumerator();
        // o padrão e o "padrão de comunicação" (o que o Discord costuma usar) podem ser microfones diferentes
        foreach (var role in new[] { Role.Console, Role.Communications })
        {
            try
            {
                using var mic = enumerator.GetDefaultAudioEndpoint(DataFlow.Capture, role);
                mic.AudioEndpointVolume.Mute = mute;
            }
            catch (System.Runtime.InteropServices.COMException) { } // esse papel não tem microfone
        }
        return mute;
    }
}
