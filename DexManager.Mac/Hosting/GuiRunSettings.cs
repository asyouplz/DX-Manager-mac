using System.Text.Json;
using System.Text.RegularExpressions;
using DexManager.Models;
using DexManager.Services;

namespace DexManager.Mac.Hosting;

// The UI edits one explicit device/mode. This boundary is deliberately independent
// of AppKit so settings validation and upstream model changes can be tested in C#.
internal sealed class GuiRunSettings
{
    public int Width { get; set; } = 1920;
    public int Height { get; set; } = 1080;
    public int Dpi { get; set; } = 150;
    public string BitRate { get; set; } = "8M";
    public int MaxFps { get; set; } = 60;
    public bool TurnScreenOff { get; set; }
    public bool StayAwake { get; set; }
    public bool UseHidKeyboard { get; set; }
    public bool UseHidMouse { get; set; }
    public bool ForceStopStartApp { get; set; }
    public bool FlexDisplay { get; set; }
    public string StartAppPackage { get; set; } = "";
    public string StartAppName { get; set; } = "";
    public string AdditionalArguments { get; set; } = "";

    internal void Validate(int mode)
    {
        if (mode < 0 || mode > 3) throw new ArgumentOutOfRangeException(nameof(mode));
        if (Width < 320 || Width > 4096 || Height < 240 || Height > 4096)
            throw new ArgumentException("Width: 320–4096; height: 240–4096. / 너비: 320~4096, 높이: 240~4096");
        if (Dpi < 120 || Dpi > 640) throw new ArgumentException("DPI must be between 120 and 640.");
        if (MaxFps < 0 || MaxFps > 240) throw new ArgumentException("FPS must be between 0 (unlimited) and 240.");
        BitRate = (BitRate ?? "").Trim();
        if (!Regex.IsMatch(BitRate, @"^[1-9][0-9]{0,8}[MK]?$", RegexOptions.IgnoreCase))
            throw new ArgumentException("Use a bitrate such as 8M. / 비트레이트 예: 8M");
        StartAppPackage = (StartAppPackage ?? "").Trim();
        if (StartAppPackage.Length > 255 || (StartAppPackage.Length > 0 &&
            !Regex.IsMatch(StartAppPackage, @"^[A-Za-z0-9_]+(\.[A-Za-z0-9_]+)+$")))
            throw new ArgumentException("Invalid Android package name. / 앱 패키지 이름을 확인하세요.");
        AdditionalArguments ??= "";
        if (AdditionalArguments.Length > 4096 || AdditionalArguments.Any(c => c is '\r' or '\n' or '\0'))
            throw new ArgumentException("Invalid additional arguments.");
        ScrcpyService.ValidateAdditionalArguments(AdditionalArguments);
    }

    internal static GuiRunSettings Read(DeviceRunSettingsProfile profile, int mode)
    {
        if (mode != 0) return Convert<GuiRunSettings>(profile.SingleWindowSlots.Single(x => x.Slot == mode));
        var result = Convert<GuiRunSettings>(profile.Scrcpy);
        result.Width = profile.VirtualDisplay.Width;
        result.Height = profile.VirtualDisplay.Height;
        result.Dpi = profile.VirtualDisplay.Dpi;
        return result;
    }

    internal void Apply(DeviceRunSettingsProfile profile, int mode)
    {
        Validate(mode);
        if (mode == 0)
        {
            profile.VirtualDisplay.Width = Width;
            profile.VirtualDisplay.Height = Height;
            profile.VirtualDisplay.Dpi = Dpi;
            // Preserve fields the UI does not own (window title, custom size, etc.).
            var target = profile.Scrcpy;
            target.BitRate = BitRate; target.MaxFps = MaxFps;
            target.TurnScreenOff = TurnScreenOff; target.StayAwake = StayAwake;
            target.UseHidKeyboard = UseHidKeyboard; target.UseHidMouse = UseHidMouse;
            target.ForceStopStartApp = ForceStopStartApp;
            target.StartAppPackage = StartAppPackage; target.StartAppName = StartAppName;
            target.AdditionalArguments = AdditionalArguments;
        }
        else
        {
            var slot = Convert<SingleWindowSlotSettings>(this);
            slot.Slot = mode;
            var index = profile.SingleWindowSlots.FindIndex(x => x.Slot == mode);
            var previous = profile.SingleWindowSlots[index];
            slot.CustomWidth = previous.CustomWidth; slot.CustomHeight = previous.CustomHeight;
            profile.SingleWindowSlots[index] = slot;
        }
    }

    internal static T Convert<T>(object value) => JsonSerializer.Deserialize<T>(JsonSerializer.Serialize(value));
}
