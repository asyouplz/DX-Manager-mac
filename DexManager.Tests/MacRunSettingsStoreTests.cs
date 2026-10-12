using DexManager.Mac.Hosting;
using DexManager.Models;
using DexManager.Services;

namespace DexManager.Tests;

public sealed class MacRunSettingsStoreTests : IDisposable
{
    private readonly string _directory = Path.Combine(
        Path.GetTempPath(), "DXManager.MacSettingsTest." + Guid.NewGuid().ToString("N"));
    private readonly SettingsService _service;
    private readonly AppSettings _settings = AppSettings.CreateDefault();
    private readonly MacRunSettingsStore _store;

    public MacRunSettingsStoreTests()
    {
        _service = new SettingsService(new LogService(), _directory);
        _store = new MacRunSettingsStore(_service, _settings);
    }

    [Fact]
    public void ReadsTheSelectedProfileWithoutCreatingOrMutatingLiveProfiles()
    {
        var selected = _settings.GetOrCreateDeviceRunSettings("phone-a");
        selected.Scrcpy.TurnScreenOff = false;
        selected.VirtualDisplay.Width = 1920;

        var displayed = _store.GetSnapshot("phone-a");
        Assert.False(displayed.Scrcpy.TurnScreenOff);
        Assert.Equal(1920, displayed.VirtualDisplay.Width);
        Assert.True(_store.GetSnapshot(null).Scrcpy.TurnScreenOff);

        displayed.Scrcpy.TurnScreenOff = true;
        _store.GetSnapshot("new-phone");
        Assert.False(selected.Scrcpy.TurnScreenOff);
        Assert.Single(_settings.DeviceRunSettingsProfiles);
        Assert.False(File.Exists(_service.SettingsFilePath));
    }

    [Fact]
    public void SavesSelectedDeviceChangesWithoutChangingDefaultsOrAnotherDevice()
    {
        _settings.GetOrCreateDeviceRunSettings("phone-a");
        _settings.GetOrCreateDeviceRunSettings("phone-b").Scrcpy.BitRate = "20M";
        _service.Save(_settings);

        _store.UpdateAndSave("phone-a", profile =>
        {
            profile.Scrcpy.TurnScreenOff = false;
            profile.Scrcpy.StayAwake = false;
            profile.VirtualDisplay.Width = 2560;
        });

        // DeX obtains this same physical-device profile regardless of ADB transport.
        var actualDexSettings = _settings.GetOrCreateDeviceRunSettings("phone-a");
        Assert.False(actualDexSettings.Scrcpy.TurnScreenOff);
        Assert.False(actualDexSettings.Scrcpy.StayAwake);
        Assert.Equal(2560, actualDexSettings.VirtualDisplay.Width);

        var loaded = _service.Load();
        Assert.False(loaded.GetOrCreateDeviceRunSettings("phone-a").Scrcpy.TurnScreenOff);
        Assert.True(loaded.Scrcpy.TurnScreenOff);
        Assert.True(loaded.Scrcpy.StayAwake);
        Assert.Equal(1600, loaded.VirtualDisplay.Width);
        Assert.True(loaded.GetOrCreateDeviceRunSettings("phone-b").Scrcpy.TurnScreenOff);
        Assert.Equal("20M", loaded.GetOrCreateDeviceRunSettings("phone-b").Scrcpy.BitRate);
    }

    [Fact]
    public void EditsNewDeviceProfileWithoutReplacingCommonDefaults()
    {
        _settings.Scrcpy.BitRate = "16M";
        _store.UpdateAndSave("new-phone", profile => profile.Scrcpy.TurnScreenOff = false);

        var loaded = _service.Load();
        Assert.Single(loaded.DeviceRunSettingsProfiles);
        Assert.True(loaded.Scrcpy.TurnScreenOff);
        Assert.False(loaded.GetOrCreateDeviceRunSettings("new-phone").Scrcpy.TurnScreenOff);
        Assert.Equal("16M", loaded.GetOrCreateDeviceRunSettings("new-phone").Scrcpy.BitRate);
    }

    [Fact]
    public void CommonDefaultChangesOnlySeedFutureDevices()
    {
        _settings.GetOrCreateDeviceRunSettings("existing-phone");
        _store.UpdateAndSave(null, profile => profile.Scrcpy.TurnScreenOff = false);

        var loaded = _service.Load();
        Assert.False(loaded.Scrcpy.TurnScreenOff);
        Assert.True(loaded.GetOrCreateDeviceRunSettings("existing-phone").Scrcpy.TurnScreenOff);
        Assert.False(loaded.GetOrCreateDeviceRunSettings("future-phone").Scrcpy.TurnScreenOff);
    }

    [Fact]
    public void FailedSaveKeepsLiveProfileAndExistingSettingsFileUnchanged()
    {
        _settings.GetOrCreateDeviceRunSettings("phone-a");
        _service.Save(_settings);
        var original = File.ReadAllBytes(_service.SettingsFilePath);

        // Only this test's temporary lock path is replaced, forcing a filesystem failure.
        var lockPath = _service.SettingsFilePath + ".lock";
        File.Delete(lockPath);
        Directory.CreateDirectory(lockPath);
        var error = Record.Exception(() => _store.UpdateAndSave("phone-a",
            profile => profile.Scrcpy.TurnScreenOff = false));

        Assert.NotNull(error);
        Assert.True(error is IOException || error is UnauthorizedAccessException);
        Assert.True(_settings.GetOrCreateDeviceRunSettings("phone-a").Scrcpy.TurnScreenOff);
        Assert.Equal(original, File.ReadAllBytes(_service.SettingsFilePath));
    }

    [Fact]
    public void SingleWindowUsesTheSameSelectedProfileAsDashboardAndDex()
    {
        var selected = _settings.GetOrCreateDeviceRunSettings("phone-a");
        selected.VirtualDisplay.Width = 2560;
        selected.VirtualDisplay.Height = 1440;
        selected.VirtualDisplay.Dpi = 240;
        selected.Scrcpy.BitRate = "24M";
        selected.Scrcpy.MaxFps = 120;
        selected.Scrcpy.TurnScreenOff = false;
        selected.Scrcpy.StayAwake = false;
        selected.SingleWindowSlots[1].StartAppPackage = "previous.app";

        var launch = _store.CreateSingleWindowSettings("phone-a", 2, "selected.app");
        Assert.Equal(2, launch.Slot);
        Assert.Equal(2560, launch.Width);
        Assert.Equal(1440, launch.Height);
        Assert.Equal(240, launch.Dpi);
        Assert.Equal("24M", launch.BitRate);
        Assert.Equal(120, launch.MaxFps);
        Assert.False(launch.TurnScreenOff);
        Assert.False(launch.StayAwake);
        Assert.Equal("selected.app", launch.StartAppPackage);
        Assert.Equal("previous.app", selected.SingleWindowSlots[1].StartAppPackage);
        Assert.True(_settings.Scrcpy.TurnScreenOff);
    }

    [Fact]
    public void RejectsTransportIdentityInsteadOfPersistingAnotherProfile()
    {
        Assert.Throws<InvalidOperationException>(() =>
            _store.UpdateAndSave("transport:USB-PENDING", profile => profile.Scrcpy.StayAwake = false));
        Assert.Throws<InvalidOperationException>(() =>
            _store.CreateSingleWindowSettings(null, 1, "selected.app"));
        Assert.Empty(_settings.DeviceRunSettingsProfiles);
        Assert.True(_settings.Scrcpy.StayAwake);
        Assert.False(File.Exists(_service.SettingsFilePath));
    }

    public void Dispose()
    {
        if (Directory.Exists(_directory)) Directory.Delete(_directory, true);
    }
}
