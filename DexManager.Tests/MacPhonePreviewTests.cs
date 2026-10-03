using System.Diagnostics;
using DexManager.Mac.Hosting;
using DexManager.Models;
using DexManager.Services;
using DexManager.Utils;

namespace DexManager.Tests;

public sealed class MacPhonePreviewTests
{
    [Theory]
    [InlineData("--hide-phone-preview", true)]
    [InlineData("--show-phone-preview", false)]
    public void CliSelectsExplicitMode(string option, bool hidden)
    {
        Assert.Equal(hidden, PhonePreviewChoice.ParseCommandLine(new[] { "--dex", option }));
        Assert.Null(PhonePreviewChoice.ParseCommandLine(new[] { "--dex" }));
    }

    [Theory]
    [InlineData("--stop-dex", "--hide-phone-preview")]
    [InlineData("--dex", "--unknown")]
    public void CliRejectsMisplacedOrUnknownOptions(string command, string option)
    {
        Assert.Throws<ArgumentException>(() => PhonePreviewChoice.ParseCommandLine(new[] { command, option }));
        Assert.Throws<ArgumentException>(() => PhonePreviewChoice.ParseCommandLine(new[] { "--dex", "--hide-phone-preview", "--show-phone-preview" }));
    }

    [Fact]
    public void ChoiceIsPerDeviceAndCannotChangeWhileRunning()
    {
        var settings = AppSettings.CreateDefault();
        PhonePreviewChoice.Apply(settings, "serial:phone", true, false);
        Assert.True(settings.GetOrCreateDeviceRunSettings("serial:phone").VirtualDisplay.HidePhonePreview);
        Assert.False(settings.GetOrCreateDeviceRunSettings("serial:other").VirtualDisplay.HidePhonePreview);
        Assert.False(settings.VirtualDisplay.HidePhonePreview);
        Assert.True(settings.GetOrCreateDeviceRunSettings("serial:phone").Scrcpy.TurnScreenOff);
        Assert.Throws<InvalidOperationException>(() => PhonePreviewChoice.Apply(settings, "serial:phone", false, true));
        Assert.Throws<InvalidOperationException>(() => PhonePreviewChoice.Apply(settings, "transport:usb", true, false));
        Assert.True(settings.GetOrCreateDeviceRunSettings("serial:phone").VirtualDisplay.HidePhonePreview);
    }

    [Fact]
    public void SharedProtocolPreservesSavedScreenPowerPreference()
    {
        var saved = AppSettings.CreateDefault().Scrcpy;
        var actual = LoopbackDexProtocol.CreateScrcpySettings(saved);
        Assert.False(actual.TurnScreenOff);
        Assert.True(saved.TurnScreenOff);
        Assert.Equal(saved.StayAwake, actual.StayAwake);
        saved.AdditionalArguments = "--turn-screen-o";
        Assert.Throws<InvalidOperationException>(() => LoopbackDexProtocol.CreateScrcpySettings(saved));
        LoopbackDexService.VerifyHelper(Path.Combine(AppContext.BaseDirectory, "tools", "loopback", "dxm-loopback.jar"));
        Assert.NotEqual("Error.Loopback.StartFailed", LocalizationService.Get("Error.Loopback.StartFailed"));
    }

    [Fact]
    public void FailedChoiceSavePreservesLivePreference()
    {
        var directory = Path.Combine(Path.GetTempPath(), "dxm-preview-save-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(directory);
        try
        {
            var settings = AppSettings.CreateDefault();
            settings.GetOrCreateDeviceRunSettings("serial:phone");
            var service = new SettingsService(new LogService(), directory);
            // A file where the config directory belongs makes SaveCore fail.
            File.WriteAllText(Path.Combine(directory, "config"), "fixture");
            Assert.ThrowsAny<IOException>(() => PhonePreviewChoice.Save(service, settings, "serial:phone", true, false));
            Assert.False(settings.GetOrCreateDeviceRunSettings("serial:phone").VirtualDisplay.HidePhonePreview);
            Assert.True(settings.GetOrCreateDeviceRunSettings("serial:phone").Scrcpy.TurnScreenOff);
        }
        finally { Directory.Delete(directory, true); }
    }

    [UnixFact]
    public void TwoHelpersHaveIndependentOwnershipAndDisconnectCleanup()
    {
        using var context = new FakeDevice();
        var first = context.Display.EnsureVirtualDisplay("phone", Hidden(), 1000, () => false);
        var second = context.Display.EnsureVirtualDisplay("other", Hidden(), 1000, () => false);
        try
        {
            Assert.NotEqual(first.LoopbackSessionId, second.LoopbackSessionId);
            Assert.True(context.IsHelperAlive("phone"));
            Assert.True(context.IsHelperAlive("other"));
            Assert.False(context.Display.Release(new VirtualDisplayLease
            {
                IsLoopback = true, Serial = "other", LoopbackSessionId = first.LoopbackSessionId
            }));
            context.Mark("disconnected-phone");
            Assert.True(context.Display.Release(first));
            Assert.False(context.IsHelperAlive("phone"));
            Assert.True(context.IsHelperAlive("other"));
            Assert.DoesNotContain(context.Lines, line => line.Contains("phone|shell rm -f"));
        }
        finally { context.Display.Release(first); context.Display.Release(second); }
        context.AssertNoOverlayMutation();
    }

    [UnixFact]
    public async Task MacOrchestratorStartsAndStopsHiddenModeWithoutPowerOffOrOverlayReset()
    {
        using var context = new FakeDevice();
        context.Settings.GetOrCreateDeviceRunSettings("serial:phone").VirtualDisplay.HidePhonePreview = true;
        Assert.True(await context.Dex.StartAsync("phone", "serial:phone", CancellationToken.None));
        Assert.True(context.Dex.CurrentSession.DisplayLease.IsLoopback);
        Assert.False(context.Scrcpy.IsScreenOffRequested);
        Assert.True(context.Settings.GetOrCreateDeviceRunSettings("serial:phone").Scrcpy.TurnScreenOff);
        Assert.DoesNotContain(" -S", context.Settings.GetOrCreateDeviceRunSettings("serial:phone").LastSuccess.ScrcpyArguments);
        Assert.True(await context.Dex.StopOrConfirmCleanupAsync());
        Assert.False(context.IsHelperAlive("phone"));
        await context.Dex.ShutdownAsync("phone", "serial:phone");
        context.AssertNoOverlayMutation();
    }

    [UnixFact]
    public async Task MacStartupCancellationClosesPendingHelperAndNeverResetsOverlay()
    {
        using var context = new FakeDevice();
        context.Mark("no-ready");
        context.Settings.GetOrCreateDeviceRunSettings("serial:phone").VirtualDisplay.HidePhonePreview = true;
        using var cancellation = new CancellationTokenSource();
        var start = context.Dex.StartAsync("phone", "serial:phone", cancellation.Token);
        await context.WaitForHelperAsync("phone");
        cancellation.Cancel();
        await Assert.ThrowsAnyAsync<OperationCanceledException>(async () => await start);
        await context.Dex.ShutdownAsync("phone", "serial:phone");
        Assert.False(context.IsHelperAlive("phone"));
        Assert.True(context.Dex.IsCleanupComplete);
        context.AssertNoOverlayMutation();
    }

    [UnixFact]
    public async Task MacHelperFailureAndShutdownDoNotFallBackToOverlay()
    {
        using var context = new FakeDevice();
        context.Mark("early-exit");
        context.Settings.GetOrCreateDeviceRunSettings("serial:phone").VirtualDisplay.HidePhonePreview = true;
        await Assert.ThrowsAsync<InvalidOperationException>(() => context.Dex.StartAsync("phone", "serial:phone", CancellationToken.None));
        await context.Dex.ShutdownAsync("phone", "serial:phone");
        Assert.False(context.IsHelperAlive("phone"));
        context.AssertNoOverlayMutation();
    }

    [UnixFact]
    public async Task ScrcpyStartFailureReleasesAlreadyCreatedLoopbackDisplay()
    {
        using var context = new FakeDevice();
        context.Mark("scrcpy-failure");
        context.Settings.GetOrCreateDeviceRunSettings("serial:phone").VirtualDisplay.HidePhonePreview = true;
        await Assert.ThrowsAsync<InvalidOperationException>(() => context.Dex.StartAsync("phone", "serial:phone", CancellationToken.None));
        Assert.True(context.Lines.Any(line => line.StartsWith("STOP|phone|")), string.Join("\n", context.Lines));
        Assert.False(context.IsHelperAlive("phone"));
        await context.Dex.ShutdownAsync("phone", "serial:phone");
        context.AssertNoOverlayMutation();
    }

    [UnixFact]
    public async Task NaturalScrcpyExitCleansLoopbackAfterPhoneDisconnect()
    {
        using var context = new FakeDevice();
        context.Settings.GetOrCreateDeviceRunSettings("serial:phone").VirtualDisplay.HidePhonePreview = true;
        Assert.True(await context.Dex.StartAsync("phone", "serial:phone", CancellationToken.None));
        context.Mark("disconnected-phone");
        using (var process = Process.GetProcessById(context.Dex.CurrentSession.ScrcpyProcessId))
            process.Kill();
        var timeout = Stopwatch.StartNew();
        while (!context.Dex.IsCleanupComplete && timeout.ElapsedMilliseconds < 5000) await Task.Delay(20);
        Assert.True(context.Dex.IsCleanupComplete);
        Assert.False(context.IsHelperAlive("phone"));
        await context.Dex.ShutdownAsync("phone", "serial:phone");
        context.AssertNoOverlayMutation();
    }

    [UnixFact]
    public async Task ChangedPhysicalIdentityIsRejectedBeforeHelperTransfer()
    {
        using var context = new FakeDevice();
        context.Settings.GetOrCreateDeviceRunSettings("serial:phone").VirtualDisplay.HidePhonePreview = true;
        await Assert.ThrowsAsync<InvalidOperationException>(() => context.Dex.StartAsync("other", "serial:phone", CancellationToken.None));
        Assert.DoesNotContain(context.Lines, line => line.Contains("|push ") || line.StartsWith("START|"));
        context.AssertNoOverlayMutation();
    }

    [UnixFact]
    public void ExistingOverlayIsPreservedAndBlocksHiddenStart()
    {
        using var context = new FakeDevice();
        context.Mark("overlay");
        Assert.Throws<InvalidOperationException>(() => context.Display.EnsureVirtualDisplay("phone", Hidden(), 1000, () => false));
        Assert.DoesNotContain(context.Lines, line => line.Contains("|push "));
        context.AssertNoOverlayMutation();
    }

    [UnixFact]
    public void ExistingVisibleModeStillCreatesAndCleansOverlay()
    {
        using var context = new FakeDevice();
        var lease = context.Display.EnsureVirtualDisplay("phone", AppSettings.CreateDefault().VirtualDisplay, 2000, () => false);
        Assert.False(lease.IsLoopback);
        Assert.Equal(7, lease.DisplayId);
        Assert.True(context.Display.Release(lease));
        Assert.Contains(context.Lines, line => line.Contains("settings put global overlay_display_devices"));
        Assert.Contains(context.Lines, line => line.Contains("settings delete global overlay_display_devices"));
        Assert.DoesNotContain(context.Lines, line => line.StartsWith("START|"));
    }

    [UnixFact]
    public void ProcessShutdownStopsOnlyOwnedChannelAndRejectsNewStarts()
    {
        using var context = new FakeDevice();
        var lease = context.Display.EnsureVirtualDisplay("phone", Hidden(), 1000, () => false);
        context.Runner.BeginShutdown();
        Assert.True(context.Display.Release(lease));
        var lines = context.Lines.Length;
        Assert.Throws<OperationCanceledException>(() => new LoopbackDexService(context.Adb, context.Log).Start("other", 1000, () => false));
        Assert.Equal(lines, context.Lines.Length);
        Assert.False(context.IsHelperAlive("phone"));
        context.AssertNoOverlayMutation();
    }

    [UnixFact]
    public void ReusedEndpointCannotReceiveNewCleanupCommands()
    {
        using var context = new FakeDevice();
        var lease = context.Display.EnsureVirtualDisplay("phone", Hidden(), 1000, () => false);
        context.Mark("replacement-phone");
        var commandsBeforeRelease = context.Lines.Count(line => line.StartsWith("phone|"));
        Assert.True(context.Display.Release(lease));
        Assert.Equal(commandsBeforeRelease, context.Lines.Count(line => line.StartsWith("phone|")));
        Assert.Contains(context.Lines, line => line.StartsWith("STOP|phone|"));
        Assert.False(context.IsHelperAlive("phone"));
        context.AssertNoOverlayMutation();
    }

    private static VirtualDisplaySettings Hidden() => new() { HidePhonePreview = true };

    private sealed class UnixFactAttribute : FactAttribute
    {
        public UnixFactAttribute()
        {
            if (OperatingSystem.IsWindows()) Skip = "macOS/POSIX host process integration";
        }
    }

    private sealed class FakeDevice : IDisposable
    {
        private readonly string _directory = Path.Combine(Path.GetTempPath(), "dxm-mac-loopback-" + Guid.NewGuid().ToString("N"));
        private readonly FileTransferCoordinator _transfers;
        public readonly AppSettings Settings = AppSettings.CreateDefault();
        public readonly LogService Log = new();
        public readonly ProcessRunner Runner;
        public readonly AdbService Adb;
        public readonly VirtualDisplayService Display;
        public readonly ScrcpyService Scrcpy;
        public readonly DexOrchestrator Dex;

        public FakeDevice()
        {
            if (OperatingSystem.IsWindows()) throw new PlatformNotSupportedException();
            Directory.CreateDirectory(_directory);
            var adbPath = Path.Combine(_directory, "fake-adb");
            var scrcpyPath = Path.Combine(_directory, "fake-scrcpy");
            File.WriteAllText(adbPath, """
                #!/bin/sh
                serial="$2"
                shift 2
                printf '%s|%s\n' "$serial" "$*" >> commands.log
                case "$*" in
                  "get-state") [ -f "disconnected-$serial" ] && exit 1; echo device ;;
                  "shell getprop ro.serialno")
                    if [ -f replacement-phone ]; then echo replacement; else echo "$serial"; fi ;;
                  "shell settings get global overlay_display_devices")
                    if [ -f overlay ]; then echo '1600x900/150,hdmi'; else echo null; fi ;;
                  "shell settings put global overlay_display_devices "*) touch overlay ;;
                  "shell settings delete global overlay_display_devices") rm -f overlay ;;
                  "shell dumpsys display")
                    if [ -f overlay ]; then printf 'mDisplayId=7\nmName="Overlay #1"\n1600 x 900, density 150\n'; fi ;;
                  *"app_process / com.dxmanager.loopback.Main "*)
                    command="$*"
                    token="${command##* }"
                    printf 'START|%s|%s|%s\n' "$serial" "$$" "$token" >> commands.log
                    [ -f early-exit ] && { echo 'DXM_LOOPBACK_ERROR fake unsupported device'; exit 2; }
                    [ -f no-ready ] || echo 'DXM_LOOPBACK_READY 41'
                    while IFS= read -r line; do
                      if [ "$line" = "STOP $token" ]; then
                        printf 'STOP|%s|%s\n' "$serial" "$token" >> commands.log
                        exit 0
                      fi
                    done ;;
                  "shell sh"*) cat >/dev/null ;;
                  "push "*|"shell rm -f "*) exit 0 ;;
                  *) echo "Unexpected fake command" >&2; exit 93 ;;
                esac
                """ + "\n");
            File.WriteAllText(scrcpyPath, """
                #!/bin/sh
                if [ "$1" = --version ]; then echo 'scrcpy 4.1'; exit 0; fi
                [ -f scrcpy-failure ] && exit 1
                exec /bin/sleep 60
                """ + "\n");
            File.SetUnixFileMode(adbPath, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute);
            File.SetUnixFileMode(scrcpyPath, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute);
            Settings.Features.ManagedFileTransferEnabled = false;
            Runner = new ProcessRunner(Log);
            Adb = new AdbService(adbPath, 1000, Runner, Log);
            Display = new VirtualDisplayService(Adb, Log);
            var sessions = new DeviceRuntimeSessionRegistry();
            var coordinator = new ScrcpyLaunchCoordinator();
            _transfers = new FileTransferCoordinator(adbPath, Settings, Log, sessions);
            Scrcpy = new ScrcpyService(scrcpyPath, 1000, Runner, Adb, coordinator, _transfers, Log);
            Dex = new DexOrchestrator(Adb, Display, Scrcpy, coordinator,
                new SettingsService(Log, _directory), Log, Settings, sessions);
        }

        public string[] Lines => File.Exists(Path.Combine(_directory, "commands.log"))
            ? File.ReadAllLines(Path.Combine(_directory, "commands.log")) : Array.Empty<string>();

        public void Mark(string name) => File.WriteAllText(Path.Combine(_directory, name), string.Empty);

        public bool IsHelperAlive(string serial)
        {
            var line = Lines.LastOrDefault(candidate => candidate.StartsWith("START|" + serial + "|", StringComparison.Ordinal));
            if (line == null) return false;
            try { using var process = Process.GetProcessById(int.Parse(line.Split('|')[2])); return !process.HasExited; }
            catch (ArgumentException) { return false; }
        }

        public async Task WaitForHelperAsync(string serial)
        {
            var timeout = Stopwatch.StartNew();
            while (!IsHelperAlive(serial) && timeout.ElapsedMilliseconds < 5000) await Task.Delay(20);
            Assert.True(IsHelperAlive(serial));
        }

        public void AssertNoOverlayMutation() => Assert.DoesNotContain(Lines, line =>
            line.Contains("settings put global overlay_display_devices") ||
            line.Contains("settings delete global overlay_display_devices"));

        public void Dispose()
        {
            Scrcpy.Stop();
            Runner.BeginShutdown();
            Scrcpy.Dispose();
            _transfers.Dispose();
            Directory.Delete(_directory, true);
        }
    }
}
