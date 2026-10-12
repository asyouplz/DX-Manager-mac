using DexManager.Models;
using DexManager.Services;

namespace DexManager.Mac.Hosting;

internal sealed class MacRunSettingsStore
{
    private readonly SettingsService _settingsService;
    private readonly AppSettings _settings;

    public MacRunSettingsStore(SettingsService settingsService, AppSettings settings)
    {
        _settingsService = settingsService ?? throw new ArgumentNullException(nameof(settingsService));
        _settings = settings ?? throw new ArgumentNullException(nameof(settings));
    }

    public DeviceRunSettingsProfile GetSnapshot(string deviceIdentity)
    {
        var snapshot = _settingsService.Clone(_settings);
        return Resolve(snapshot, deviceIdentity);
    }

    public void UpdateAndSave(string deviceIdentity, Action<DeviceRunSettingsProfile> update)
    {
        ArgumentNullException.ThrowIfNull(update);
        _settingsService.UpdateAndSave(_settings, candidate =>
            update(Resolve(candidate, deviceIdentity)));
    }

    public SingleWindowSlotSettings CreateSingleWindowSettings(
        string deviceIdentity, int slot, string appPackage)
    {
        if (string.IsNullOrWhiteSpace(deviceIdentity))
            throw new InvalidOperationException("Wait for a stable device identity before starting a window.");
        if (slot < 1 || slot > 3) throw new ArgumentOutOfRangeException(nameof(slot));

        var profile = GetSnapshot(deviceIdentity);
        return new SingleWindowSlotSettings
        {
            Slot = slot,
            Width = profile.VirtualDisplay.Width,
            Height = profile.VirtualDisplay.Height,
            Dpi = profile.VirtualDisplay.Dpi,
            BitRate = profile.Scrcpy.BitRate,
            MaxFps = profile.Scrcpy.MaxFps,
            StayAwake = profile.Scrcpy.StayAwake,
            TurnScreenOff = profile.Scrcpy.TurnScreenOff,
            StartAppPackage = appPackage,
            AdditionalArguments = profile.Scrcpy.AdditionalArguments
        };
    }

    private static DeviceRunSettingsProfile Resolve(AppSettings settings, string deviceIdentity)
    {
        deviceIdentity = (deviceIdentity ?? string.Empty).Trim();
        if (deviceIdentity.Length > 0)
        {
            if (PhysicalDeviceRegistry.IsTemporaryIdentity(deviceIdentity))
                throw new InvalidOperationException("Wait for a stable device identity before changing device settings.");
            return settings.GetOrCreateDeviceRunSettings(deviceIdentity);
        }

        // No selected device: edit only the defaults used to seed future profiles.
        return new DeviceRunSettingsProfile
        {
            DeviceIdentity = string.Empty,
            VirtualDisplay = settings.VirtualDisplay,
            Scrcpy = settings.Scrcpy,
            LastSuccess = settings.LastSuccess,
            SingleWindowSlots = settings.SingleWindowSlots,
            SingleWindowAppProfiles = settings.SingleWindowAppProfiles
        };
    }
}
