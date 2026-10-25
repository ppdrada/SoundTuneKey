using System.Runtime.InteropServices;

namespace SoundTuneKey;

[Flags]
public enum HotkeyModifiers : uint
{
    Alt = 0x1,
    Control = 0x2,
    Shift = 0x4,
    Win = 0x8,
    NoRepeat = 0x4000, // segurar a tecla não dispara de novo
}

/// <summary>
/// Atalhos globais do Windows (RegisterHotKey): funcionam mesmo com outro app ou jogo em primeiro plano.
/// Usa uma janela invisível só para receber as mensagens de atalho.
/// </summary>
public sealed class GlobalHotkeys : NativeWindow, IDisposable
{
    private const int WM_HOTKEY = 0x0312;

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll")]
    private static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    private readonly Dictionary<int, Action> _actions = [];
    private int _nextId = 1;

    public GlobalHotkeys() => CreateHandle(new CreateParams());

    /// <summary>
    /// Registra o atalho. Retorna false se outro programa já usa a mesma combinação.
    /// </summary>
    public bool Register(HotkeyModifiers modifiers, Keys key, Action action)
    {
        int id = _nextId++;
        if (!RegisterHotKey(Handle, id, (uint)modifiers, (uint)key))
            return false;

        _actions[id] = action;
        return true;
    }

    protected override void WndProc(ref Message m)
    {
        if (m.Msg == WM_HOTKEY && _actions.TryGetValue((int)m.WParam, out var action))
            action();

        base.WndProc(ref m);
    }

    public void Dispose()
    {
        foreach (var id in _actions.Keys)
            UnregisterHotKey(Handle, id);

        _actions.Clear();
        DestroyHandle();
    }
}
