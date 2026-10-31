using DexManager.Mac.Hosting;
using DexManager.Models;
using DexManager.Services;

namespace DexManager.Tests;

// Host-side checks for the hidden-preview DeX port. Samsung device behavior
// (preview hiding, disconnect cleanup time) is physical acceptance work.
public sealed class LoopbackDexTests : IDisposable
{
    private const string Token = "0123456789abcdef0123456789abcdef";
    private readonly string directory = Path.Combine(Path.GetTempPath(), "DXM.LoopbackTest." + Guid.NewGuid().ToString("N"));

    [Fact]
    public void ShellCommandIsBoundToUniqueSafeToken()
    {
        var path = LoopbackDexProtocol.CreateRemotePath(Token);
        Assert.Equal("/data/local/tmp/dxm-loopback-" + Token + ".jar", path);
        Assert.Equal("CLASSPATH=" + path + " app_process / com.dxmanager.loopback.Main " + Token,
            LoopbackDexProtocol.BuildShellCommand(Token));
        Assert.NotEqual(path, LoopbackDexProtocol.CreateRemotePath(new string('1', 32)));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("123")]
    [InlineData("0123456789abcdef0123456789abcde")]
    [InlineData("0123456789abcdef0123456789abcdef0")]
    [InlineData("ABCDEF0123456789ABCDEF0123456789")]
    [InlineData("gggggggggggggggggggggggggggggggg")]
    [InlineData("0123456789abcdef0123456789abcdef\n")]
    [InlineData("../../etc/passwd")]
    [InlineData("a;reboot")]
    [InlineData("$(id)")]
    public void InvalidTokensAreRejected(string token)
    {
        Assert.Throws<ArgumentException>(() => LoopbackDexProtocol.CreateRemotePath(token));
        Assert.Throws<ArgumentException>(() => LoopbackDexProtocol.BuildShellCommand(token));
    }

    [Fact]
    public void ReadyMessageAcceptsOnlyExactPositiveDisplayId()
    {
        Assert.True(LoopbackDexProtocol.TryParseReady("DXM_LOOPBACK_READY 1", out var one));
        Assert.Equal(1, one);
        Assert.True(LoopbackDexProtocol.TryParseReady("DXM_LOOPBACK_READY 2147483647", out var max));
        Assert.Equal(int.MaxValue, max);
        foreach (var line in new[] { null, "", "DXM_LOOPBACK_READY 0", "DXM_LOOPBACK_READY -1",
            "DXM_LOOPBACK_READY 01", "DXM_LOOPBACK_READY +1", "DXM_LOOPBACK_READY 2147483648",
            "DXM_LOOPBACK_READY 9\n", "DXM_LOOPBACK_READY 9 ", " DXM_LOOPBACK_READY 9",
            "log: DXM_LOOPBACK_READY 9", "DXM_LOOPBACK_READY 1;reboot", "DXM_LOOPBACK_READY 1 2" })
        {
            Assert.False(LoopbackDexProtocol.TryParseReady(line, out var id));
            Assert.Equal(0, id);
        }
    }

    [Theory]
    [InlineData("-S")]
    [InlineData("-fS")]
    [InlineData("-Sf")]
    [InlineData("--turn-screen-off")]
    [InlineData("--turn-screen-off=true")]
    [InlineData("--turn-s")]
    [InlineData("--power-off-on-close")]
    [InlineData("--power-off")]
    [InlineData("--no-power-on")]
    [InlineData("--no-p")]
    [InlineData("--video-codec=h264 -S")]
    [InlineData("\"--turn-screen-off\"")]
    public void PowerControlArgumentsAreRejected(string arguments)
    {
        Assert.Throws<InvalidOperationException>(() => LoopbackDexProtocol.ValidateAdditionalArguments(arguments));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("--video-codec=h264 --max-fps=60")]
    [InlineData("--no-audio")]
    [InlineData("-f")]
    [InlineData("--stay-awake")]
    public void NonPowerArgumentsAreAllowed(string arguments)
    {
        LoopbackDexProtocol.ValidateAdditionalArguments(arguments);
    }

    [Fact]
    public void EffectiveSettingsKeepPhoneOnWithoutChangingSavedPreference()
    {
        var source = AppSettings.CreateDefault().Scrcpy;
        source.TurnScreenOff = true; source.BitRate = "12M"; source.MaxFps = 90;
        source.AdditionalArguments = "--no-audio";
        var effective = LoopbackDexProtocol.CreateScrcpySettings(source);
        Assert.NotSame(source, effective);
        Assert.False(effective.TurnScreenOff);
        Assert.True(source.TurnScreenOff);
        Assert.Equal("12M", effective.BitRate);
        Assert.Equal(90, effective.MaxFps);
        Assert.Equal("--no-audio", effective.AdditionalArguments);
        Assert.Throws<ArgumentNullException>(() => LoopbackDexProtocol.CreateScrcpySettings(null));
        source.AdditionalArguments = "-S";
        Assert.Throws<InvalidOperationException>(() => LoopbackDexProtocol.CreateScrcpySettings(source));
    }

    [Fact]
    public void CheckedInHelperMatchesPinnedHash()
    {
        var helper = Path.Combine(FindRepositoryRoot(), "tools", "loopback", "dxm-loopback.jar");
        LoopbackDexService.VerifyHelper(helper);
        var sidecar = File.ReadAllText(helper + ".sha256").Split(' ')[0].Trim();
        Assert.Equal(LoopbackDexService.HelperSha256, sidecar, ignoreCase: true);
    }

    [Fact]
    public void ModifiedOrMissingHelperIsRejected()
    {
        Directory.CreateDirectory(directory);
        var forged = Path.Combine(directory, "dxm-loopback.jar");
        File.WriteAllText(forged, "not the reviewed helper");
        Assert.Throws<InvalidOperationException>(() => LoopbackDexService.VerifyHelper(forged));
        Assert.Throws<InvalidOperationException>(() => LoopbackDexService.VerifyHelper(Path.Combine(directory, "missing.jar")));
    }

    [Fact]
    public void HelperIsFoundInPortableFolderOrAppBundleResources()
    {
        var portable = Path.Combine(directory, "portable");
        var portableJar = Path.Combine(portable, "tools", "loopback", "dxm-loopback.jar");
        Directory.CreateDirectory(Path.GetDirectoryName(portableJar));
        File.WriteAllText(portableJar, "x");
        Assert.Equal(portableJar, LoopbackDexService.FindHelper(portable));

        var macOs = Path.Combine(directory, "DX Manager.app", "Contents", "MacOS");
        var bundledJar = Path.Combine(directory, "DX Manager.app", "Contents", "Resources", "tools", "loopback", "dxm-loopback.jar");
        Directory.CreateDirectory(macOs);
        Directory.CreateDirectory(Path.GetDirectoryName(bundledJar));
        File.WriteAllText(bundledJar, "x");
        Assert.Equal(Path.GetFullPath(bundledJar), LoopbackDexService.FindHelper(macOs));
    }

    [Fact]
    public void HiddenPreviewIsOffByDefaultAndSavedPerDevice()
    {
        var service = new SettingsService(new LogService(), directory);
        var settings = AppSettings.CreateDefault();
        Assert.False(settings.VirtualDisplay.HidePhonePreview);
        settings.GetOrCreateDeviceRunSettings("phone-a");
        settings.GetOrCreateDeviceRunSettings("phone-b");
        var store = new MacRunSettingsStore(service, settings);
        var run = GuiRunSettings.Read(store.GetSnapshot("phone-a"), 0);
        Assert.False(run.HidePhonePreview);
        run.HidePhonePreview = true;
        store.UpdateAndSave("phone-a", p => run.Apply(p, 0));

        var loaded = service.Load();
        Assert.True(loaded.GetOrCreateDeviceRunSettings("phone-a").VirtualDisplay.HidePhonePreview);
        Assert.False(loaded.GetOrCreateDeviceRunSettings("phone-b").VirtualDisplay.HidePhonePreview);
        Assert.False(loaded.VirtualDisplay.HidePhonePreview);
        Assert.True(GuiRunSettings.Read(store.GetSnapshot("phone-a"), 0).HidePhonePreview);
    }

    [Fact]
    public void HiddenPreviewKeepsSavedResolutionAndScreenOffPreference()
    {
        var profile = AppSettings.CreateDefault().GetOrCreateDeviceRunSettings("phone-a");
        var run = GuiRunSettings.Read(profile, 0);
        run.Width = 2560; run.Height = 1440; run.Dpi = 200; run.TurnScreenOff = true; run.HidePhonePreview = true;
        run.Apply(profile, 0);
        run.HidePhonePreview = false; run.Apply(profile, 0);
        Assert.Equal(2560, profile.VirtualDisplay.Width);
        Assert.Equal(200, profile.VirtualDisplay.Dpi);
        Assert.True(profile.Scrcpy.TurnScreenOff);
        Assert.False(profile.VirtualDisplay.HidePhonePreview);
    }

    [Fact]
    public void HiddenPreviewRejectsPowerArgumentsAndIsIgnoredForSingleWindows()
    {
        var run = new GuiRunSettings { HidePhonePreview = true, AdditionalArguments = "--turn-screen-off" };
        Assert.Throws<InvalidOperationException>(() => run.Validate(0));
        var slot = new GuiRunSettings { HidePhonePreview = true };
        slot.Validate(1);
        Assert.False(slot.HidePhonePreview);
    }

    [Fact]
    public void CloneCarriesHiddenPreviewFlag()
    {
        var clone = AppSettings.CloneVirtualDisplay(new VirtualDisplaySettings { HidePhonePreview = true });
        Assert.True(clone.HidePhonePreview);
    }

    [Fact]
    public void ReleaseOfUnknownOrNonLoopbackLeaseIsANoOp()
    {
        var log = new LogService();
        var adb = new AdbService("/usr/bin/false", 1000, new DexManager.Utils.ProcessRunner(log), log);
        var loopback = new LoopbackDexService(adb, log);
        Assert.True(loopback.Release(null));
        Assert.True(loopback.Release(new VirtualDisplayLease { Serial = "a", DisplayId = 3 }));
        Assert.True(loopback.Release(new VirtualDisplayLease { Serial = "a", IsLoopback = true, LoopbackSessionId = Token }));
    }

    private static string FindRepositoryRoot()
    {
        for (var current = new DirectoryInfo(AppContext.BaseDirectory); current != null; current = current.Parent)
            if (File.Exists(Path.Combine(current.FullName, "DexManager.Mac.sln"))) return current.FullName;
        throw new DirectoryNotFoundException("Repository root not found.");
    }

    public void Dispose()
    {
        if (Directory.Exists(directory)) Directory.Delete(directory, true);
    }
}
