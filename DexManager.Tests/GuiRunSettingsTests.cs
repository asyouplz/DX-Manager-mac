using DexManager.Mac.Hosting;
using DexManager.Models;
using DexManager.Services;

namespace DexManager.Tests;

public sealed class GuiRunSettingsTests : IDisposable
{
    private readonly string directory = Path.Combine(Path.GetTempPath(), "DXM.GuiTest." + Guid.NewGuid().ToString("N"));

    [Fact]
    public void SavingOneSlotPreservesOtherModesDevicesAndDefaultsAfterReload()
    {
        var service = new SettingsService(new LogService(), directory);
        var settings = AppSettings.CreateDefault();
        settings.GetOrCreateDeviceRunSettings("phone-a");
        settings.GetOrCreateDeviceRunSettings("phone-b");
        var store = new MacRunSettingsStore(service, settings);
        var original = GuiRunSettings.Read(store.GetSnapshot("phone-a"), 0);
        var change = new GuiRunSettings { Width = 2560, Height = 1440, Dpi = 220,
            BitRate = "20M", MaxFps = 120, StartAppPackage = "org.example.app", StartAppName = "Example",
            TurnScreenOff = false, StayAwake = true, FlexDisplay = true, UseHidKeyboard = true, UseHidMouse = true };
        store.UpdateAndSave("phone-a", p => change.Apply(p, 2));
        var loaded = service.Load();
        var actual = loaded.GetOrCreateDeviceRunSettings("phone-a");
        Assert.Equal(2560, actual.SingleWindowSlots[1].Width);
        Assert.True(actual.SingleWindowSlots[1].UseHidKeyboard);
        Assert.True(actual.SingleWindowSlots[1].UseHidMouse);
        Assert.True(actual.SingleWindowSlots[1].FlexDisplay);
        Assert.Equal("org.example.app", actual.SingleWindowSlots[1].StartAppPackage);
        Assert.Equal(original.Width, actual.VirtualDisplay.Width);
        Assert.NotEqual(2560, actual.SingleWindowSlots[0].Width);
        Assert.NotEqual(2560, loaded.GetOrCreateDeviceRunSettings("phone-b").SingleWindowSlots[1].Width);
        Assert.NotEqual(2560, loaded.SingleWindowSlots[1].Width);
    }

    [Fact]
    public void DexSavePreservesHiddenModelFieldsAndDoesNotOverwriteSlots()
    {
        var settings = AppSettings.CreateDefault();
        var profile = settings.GetOrCreateDeviceRunSettings("phone-a");
        profile.Scrcpy.WindowTitle = "preserve";
        profile.VirtualDisplay.Suffix = "hdmi";
        var run = GuiRunSettings.Read(profile, 0);
        run.UseHidKeyboard = true; run.Width = 2560; run.Apply(profile, 0);
        Assert.Equal("preserve", profile.Scrcpy.WindowTitle);
        Assert.Equal("hdmi", profile.VirtualDisplay.Suffix);
        Assert.True(profile.Scrcpy.UseHidKeyboard);
        Assert.NotEqual(2560, profile.SingleWindowSlots[0].Width);
    }

    [Theory]
    [InlineData("--serial another-device")]
    [InlineData("--display-id=99")]
    [InlineData("-s another-device")]
    [InlineData("--port=5555\n--no-control")]
    public void RejectsArgumentsThatEscapeManagedDeviceOrDisplay(string arguments)
    {
        var run = new GuiRunSettings { AdditionalArguments = arguments };
        Assert.ThrowsAny<Exception>(() => run.Validate(0));
    }

    [Theory]
    [InlineData("com.example.app --serial stolen")]
    [InlineData("; rm -rf /sdcard")]
    [InlineData("com.example.app\nother")]
    public void RejectsPackageNamesContainingAdditionalCommands(string package)
    {
        Assert.Throws<ArgumentException>(() => new GuiRunSettings { StartAppPackage = package }.Validate(1));
    }

    [Fact]
    public void ValidationFailureDoesNotPersistPartialDeviceEdits()
    {
        var service = new SettingsService(new LogService(), directory);
        var settings = AppSettings.CreateDefault();
        var store = new MacRunSettingsStore(service, settings);
        service.Save(settings); var before = File.ReadAllBytes(service.SettingsFilePath);
        Assert.Throws<ArgumentException>(() => store.UpdateAndSave("phone-a", p => new GuiRunSettings { Dpi = -1 }.Apply(p, 0)));
        Assert.Equal(before, File.ReadAllBytes(service.SettingsFilePath));
        Assert.Empty(settings.DeviceRunSettingsProfiles);
    }

    public void Dispose() { if (Directory.Exists(directory)) Directory.Delete(directory, true); }
}
