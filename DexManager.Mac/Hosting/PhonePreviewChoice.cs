using DexManager.Models;
using DexManager.Services;

namespace DexManager.Mac.Hosting;

internal static class PhonePreviewChoice
{
    internal static bool? ParseCommandLine(string[] args)
    {
        if (args.Length < 2) return null;
        if (args.Length != 2 || (args[0] != "--dex" && args[0] != "-x"))
            throw new ArgumentException("Phone preview options must follow --dex or -x.");
        return args[1] switch
        {
            "--hide-phone-preview" => true,
            "--show-phone-preview" => false,
            _ => throw new ArgumentException("Unknown DeX option: " + args[1])
        };
    }

    internal static void Apply(AppSettings settings, string identity, bool hidden,
        bool runningOrStarting)
    {
        if (runningOrStarting)
            throw new InvalidOperationException("Stop DeX before changing the phone preview mode. / DeX를 먼저 중지하세요.");
        if (string.IsNullOrWhiteSpace(identity) || PhysicalDeviceRegistry.IsTemporaryIdentity(identity))
            throw new InvalidOperationException("A verified connected phone is required to save this choice.");
        settings.GetOrCreateDeviceRunSettings(identity).VirtualDisplay.HidePhonePreview = hidden;
    }

    internal static void Save(SettingsService service, AppSettings settings,
        string identity, bool hidden, bool runningOrStarting)
    {
        // The live choice changes only after the candidate is written successfully.
        service.UpdateAndSave(settings, candidate => Apply(candidate, identity, hidden, runningOrStarting));
    }

    internal static string Describe(bool hidden) => hidden
        ? "Hidden (experimental) / 휴대폰 DeX 숨김 (실험)"
        : "Shown (existing mode) / 휴대폰 DeX 표시 (기존 방식)";
}
