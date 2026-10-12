using System.Text.RegularExpressions;
using DexManager.Models;

namespace DexManager.Mac.Hosting;

internal sealed class GuiDesktopSettings
{
    public bool Enabled { get; set; } = true;
    public bool Hangul { get; set; } = true;
    public bool Enter { get; set; }
    public bool IgnoreShiftSpace { get; set; }
    public bool RightCommand { get; set; } = true;
    public int HangulMode { get; set; } = 1;
    public int EnterMode { get; set; } = 1;
    public string CaptureHotkey { get; set; } = "F8";
    public string ExitHotkey { get; set; } = "LeftAlt+F8";
    public int CaptureWait { get; set; } = 5;
    public bool MiniBar { get; set; } = true;
    public int MiniSide { get; set; }
    public string ScreenshotFolder { get; set; } = "";
    public string PhoneScreenshotFolder { get; set; } = "/sdcard/DCIM/DeX Screenshots";
    public bool PushCapture { get; set; } = true;

    internal static string NormalizeShortcut(string text)
    {
        var value = (text ?? "").Replace("LeftAlt", "Option", StringComparison.OrdinalIgnoreCase)
            .Replace("Alt", "Option", StringComparison.OrdinalIgnoreCase)
            .Replace("Control", "Ctrl", StringComparison.OrdinalIgnoreCase)
            .Replace("Command", "Cmd", StringComparison.OrdinalIgnoreCase);
        var parts = value.Split('+', StringSplitOptions.TrimEntries);
        if (parts.Length == 0 || !Regex.IsMatch(parts[^1], @"^F([1-9]|1[0-9]|20)$", RegexOptions.IgnoreCase))
            throw new ArgumentException("Use F1–F20 with optional Ctrl, Option, Shift or Cmd. / F1~F20과 Ctrl·Option·Shift·Cmd를 사용하세요.");
        var modifiers = parts[..^1].Select(x => x.ToLowerInvariant()).ToArray();
        if (modifiers.Any(x => x is not ("ctrl" or "option" or "shift" or "cmd")) || modifiers.Distinct().Count() != modifiers.Length)
            throw new ArgumentException("Invalid shortcut modifiers.");
        return string.Join('+', modifiers.OrderBy(x => x).Append(parts[^1].ToUpperInvariant()));
    }
    internal void Validate()
    {
        if (NormalizeShortcut(CaptureHotkey) == NormalizeShortcut(ExitHotkey)) throw new ArgumentException("Capture and stop shortcuts must differ. / 캡처와 중지 단축키를 다르게 지정하세요.");
        if (CaptureWait is < 1 or > 60 || MiniSide is < 0 or > 1 || HangulMode is < 0 or > 2 || EnterMode is < 0 or > 2) throw new ArgumentException("Invalid desktop settings.");
        if (!Path.IsPathFullyQualified(ScreenshotFolder) || ScreenshotFolder.Contains('\0')) throw new ArgumentException("Choose an absolute screenshot folder.");
        if (!PhoneScreenshotFolder.StartsWith("/sdcard/", StringComparison.Ordinal) || PhoneScreenshotFolder.IndexOfAny(new[] {'\0','\n','\r'}) >= 0 || PhoneScreenshotFolder.Split('/').Contains(".."))
            throw new ArgumentException("The phone screenshot folder must be under /sdcard/.");
    }
    internal static GuiDesktopSettings Read(AppSettings s, string defaultFolder) => new()
    {
        Enabled=s.KeyMappings.UseLowLevelHotkeys, Hangul=s.KeyMappings.ConvertKoreanEnglishKey,
        Enter=s.KeyMappings.ConvertEnterToShiftEnter, IgnoreShiftSpace=s.KeyMappings.IgnoreShiftSpace,
        RightCommand=s.KeyMappings.HandleRightWindowsKey, HangulMode=(int)s.KeyMappings.KoreanEnglishInputMode,
        EnterMode=(int)s.KeyMappings.EnterInputMode, CaptureHotkey=s.KeyMappings.CaptureHotkey,
        ExitHotkey=s.KeyMappings.ExitHotkey, CaptureWait=s.Timing.CaptureWaitSeconds,
        MiniBar=s.Features.MiniControlBarEnabled, MiniSide=(int)s.Features.MiniControlBarSide,
        ScreenshotFolder=Path.IsPathFullyQualified(s.Paths.ScreenshotFolder) ? s.Paths.ScreenshotFolder : defaultFolder,
        PhoneScreenshotFolder=s.Paths.DeviceScreenshotFolder, PushCapture=s.Features.PushCaptureToDevice
    };
    internal void Apply(AppSettings s)
    {
        Validate(); s.KeyMappings.UseLowLevelHotkeys=Enabled; s.KeyMappings.ConvertKoreanEnglishKey=Hangul;
        s.KeyMappings.ConvertEnterToShiftEnter=Enter; s.KeyMappings.IgnoreShiftSpace=IgnoreShiftSpace;
        s.KeyMappings.HandleRightWindowsKey=RightCommand; s.KeyMappings.KoreanEnglishInputMode=(KeyInputMode)HangulMode;
        s.KeyMappings.EnterInputMode=(KeyInputMode)EnterMode; s.KeyMappings.CaptureHotkey=NormalizeShortcut(CaptureHotkey);
        s.KeyMappings.ExitHotkey=NormalizeShortcut(ExitHotkey); s.Timing.CaptureWaitSeconds=CaptureWait;
        s.Features.MiniControlBarEnabled=MiniBar; s.Features.MiniControlBarSide=(MiniControlBarSide)MiniSide;
        s.Paths.ScreenshotFolder=ScreenshotFolder; s.Paths.DeviceScreenshotFolder=PhoneScreenshotFolder;
        s.Features.PushCaptureToDevice=PushCapture;
    }
    internal static void ValidateCaptureFile(string path, string folder)
    {
        var root=Path.GetFullPath(folder).TrimEnd(Path.DirectorySeparatorChar)+Path.DirectorySeparatorChar;
        var file=Path.GetFullPath(path);
        if (!file.StartsWith(root, StringComparison.Ordinal) || !Regex.IsMatch(Path.GetFileName(file), @"^DXM_[0-9a-fA-F-]{36}\.png$")) throw new ArgumentException("Unexpected capture path.");
        if (new FileInfo(file).LinkTarget != null) throw new ArgumentException("Capture symlinks are not supported.");
        using var stream=File.OpenRead(file); Span<byte> header=stackalloc byte[8];
        if (stream.Read(header)!=8 || !header.SequenceEqual(new byte[]{137,80,78,71,13,10,26,10})) throw new ArgumentException("The capture is not a PNG image.");
    }
}
