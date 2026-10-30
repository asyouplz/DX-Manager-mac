using System.Text.Json;
using System.Collections.Concurrent;
using DexManager.Models;
using DexManager.Services;

namespace DexManager.Mac.Hosting;

public sealed partial class InteractiveHost
{
    private readonly Dictionary<string, DeviceRuntimeServiceSet> _guiRuntimes = new(StringComparer.OrdinalIgnoreCase);

    private readonly ConcurrentDictionary<string, object> _guiTransferProgress = new(StringComparer.OrdinalIgnoreCase);
    private readonly ConcurrentDictionary<string, object> _guiReceiveProgress = new(StringComparer.OrdinalIgnoreCase);

    internal void StartGuiMonitor() => _deviceMonitor.Start();

    private PhysicalDeviceInfo GuiDevice(string identity) => _deviceRegistry.Current.Devices.FirstOrDefault(d =>
        string.Equals(d.Identity, identity, StringComparison.OrdinalIgnoreCase));

    private PhysicalDeviceInfo RequireGuiDevice(string identity)
    {
        if (string.IsNullOrWhiteSpace(identity) || PhysicalDeviceRegistry.IsTemporaryIdentity(identity))
            throw new InvalidOperationException("Select an authorized device first. / 연결 승인된 기기를 선택하세요.");
        var device = GuiDevice(identity);
        if (device?.IsConnected != true) throw new InvalidOperationException("The selected device is disconnected. / 선택 기기의 연결이 끊어졌습니다.");
        var serial = device.SelectPreferredTransport(null)?.Serial;
        // Revalidate the physical identity immediately before any device operation.
        if (string.IsNullOrEmpty(serial) || !_adbService.IsAuthorizedDeviceConnected(serial) ||
            !string.Equals(_adbService.GetDeviceIdentity(serial), identity, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Device identity changed. Refresh and select the device again. / 기기를 다시 선택하세요.");
        return device;
    }

    private DeviceRuntimeServiceSet GuiRuntime(string identity)
    {
        if (!_guiRuntimes.TryGetValue(identity, out var runtime))
        {
            _guiRuntimes.Add(identity, runtime = _runtimeFactory.Create());
            runtime.FileTransfers.ProgressChanged += (_, e) =>
            {
                var p = e.Progress;
                _guiTransferProgress[identity] = new { requestId = p.RequestId, stage = p.Stage.ToString(),
                    item = p.FileName, bytes = p.FileSize, completed = p.CompletedCount,
                    failed = p.FailedCount, queued = p.QueuedCount, message = p.Message };
            };
            runtime.PhoneTransfers.ProgressChanged += (_, e) =>
            {
                var p = e.Progress;
                _guiReceiveProgress[identity] = new { stage = p.Stage.ToString(), item = p.CurrentItem,
                    completed = p.CompletedItems, total = p.TotalItems, bytes = p.ReceivedBytes, error = p.Error };
            };
        }
        return runtime;
    }

    private IEnumerable<object> GuiSessions()
    {
        foreach (var pair in _guiRuntimes)
            for (var mode = 0; mode <= 3; mode++)
                if (GuiNativeSession(pair.Value, mode, out var pid, out _, out var display))
                    yield return new { device = pair.Key, mode, pid, displayId = display };
    }
    private static bool GuiNativeSession(DeviceRuntimeServiceSet runtime, int mode, out int pid, out string serial, out int display)
        => mode == 0 ? runtime.Scrcpy.TryGetNativeSession(out pid, out serial, out display)
                     : runtime.SingleWindows.TryGetNativeSession(mode, out pid, out serial, out display);
    private (string serial, int displayId) RequireOwnedGuiSession(string identity, int mode, int expectedPid)
    {
        // Local cleanup must remain possible after the phone disconnects.
        if (expectedPid <= 0 || !_guiRuntimes.TryGetValue(identity, out var runtime) ||
            !GuiNativeSession(runtime, mode, out var pid, out var serial, out var display) || pid != expectedPid)
            throw new InvalidOperationException("The target session has ended or changed. / 대상 실행 세션이 종료되거나 바뀌었습니다.");
        return (serial, display);
    }
    private (string serial, int displayId) RequireGuiSession(string identity, int mode, int expectedPid)
    {
        RequireGuiDevice(identity);
        var session = RequireOwnedGuiSession(identity, mode, expectedPid);
        if (!_adbService.IsAuthorizedDeviceConnected(session.serial) ||
            !string.Equals(_adbService.GetDeviceIdentity(session.serial), identity, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Device identity changed. / 대상 기기가 바뀌었습니다.");
        return session;
    }

    internal async Task<object> ExecuteGuiAsync(string command, JsonElement request, CancellationToken token)
    {
        var identity = request.TryGetProperty("device", out var id) ? id.GetString() ?? "" : "";
        var mode = request.TryGetProperty("mode", out var m) ? m.GetInt32() : 0;
        if (mode < 0 || mode > 3) throw new ArgumentOutOfRangeException(nameof(mode));
        string Text(string name) => request.TryGetProperty(name, out var p) ? p.GetString() ?? "" : "";
        int Number(string name, int fallback) => request.TryGetProperty(name, out var p) ? p.GetInt32() : fallback;
        bool Flag(string name) => request.TryGetProperty(name, out var p) && p.GetBoolean();
        switch (command)
        {
            case "state":
                return new
                {
                    protocol = 1, version = Program.Version, sessions = GuiSessions().ToArray(),
                    transfers = _guiTransferProgress.ToArray().ToDictionary(p => p.Key, p => p.Value),
                    receives = _guiReceiveProgress.ToArray().ToDictionary(p => p.Key, p => p.Value),
                    devices = _deviceRegistry.Current.Devices.Select(d => new
                    {
                        identity = d.Identity, name = d.DisplayName, connected = d.IsConnected,
                        stable = !PhysicalDeviceRegistry.IsTemporaryIdentity(d.Identity),
                        transport = d.SelectPreferredTransport(null)?.Kind.ToString(),
                        running = Enumerable.Range(0, 4).Select(slot => _guiRuntimes.TryGetValue(d.Identity, out var r) &&
                            (slot == 0 ? r.Dex.IsRunning : r.SingleWindows.IsRunning(slot))).ToArray()
                    }).ToArray(),
                    // Keep disconnected running sessions selectable so Stop remains possible.
                    detached = _guiRuntimes.Where(pair => GuiDevice(pair.Key) == null).Select(pair => new
                    {
                        identity = pair.Key, name = "Disconnected / 연결 끊김", connected = false, stable = true,
                        transport = "", running = Enumerable.Range(0, 4).Select(slot => slot == 0 ? pair.Value.Dex.IsRunning : pair.Value.SingleWindows.IsRunning(slot)).ToArray()
                    }).ToArray()
                };
            case "settings":
                return new
                {
                    run = GuiRunSettings.Read(_runSettings.GetSnapshot(identity), mode),
                    desktop = GuiDesktopSettings.Read(_settings, _pathProvider.DefaultScreenshotFolder),
                    general = new
                    {
                        language = (int)_settings.Language, theme = (int)_settings.Theme,
                        autoStart = _settings.Features.AutoStartDexOnDeviceConnected,
                        startDelay = _settings.Timing.ConnectedStartDelayMs / 1000,
                        autoHide = _settings.Features.AutoHideEnabled,
                        hideDelay = _settings.Timing.AutoHideIdleSeconds,
                        startMinimized = _settings.Features.StartMinimizedToTray,
                        login = _autoStartService.IsRegistered(),
                        managedTransfer = _settings.Features.ManagedFileTransferEnabled,
                        phoneTransfer = _settings.Features.PhoneToPcTransferEnabled,
                        restoreAwake = _settings.Features.DisableStayAwakeOnStop
                    },
                    paths = new { adb = _adbService.AdbPath, scrcpy = _settings.Paths.ScrcpyPath,
                        config = _pathProvider.DefaultSettingsFilePath, logs = _logService.LogDirectory,
                        send = _settings.Paths.FileTransferTargetFolder, receive = _settings.Paths.PhoneToPcReceiveFolder },
                    wireless = string.IsNullOrEmpty(identity) ? null : _settings.FindDeviceWirelessConnection(identity),
                    profiles = _runSettings.GetSnapshot(identity).SingleWindowAppProfiles
                };
            case "desktop":
                var desktop = request.GetProperty("desktop").Deserialize<GuiDesktopSettings>(GuiProtocol.Json);
                desktop.Validate(); _settingsService.UpdateAndSave(_settings, desktop.Apply);
                return new { message = "Desktop settings saved. / 키·캡처·미니바 설정을 저장했습니다." };
            case "capture-finish":
                var capturePath = Text("path");
                GuiDesktopSettings.ValidateCaptureFile(capturePath, GuiDesktopSettings.Read(_settings, _pathProvider.DefaultScreenshotFolder).ScreenshotFolder);
                try
                {
                    var captureSession = RequireGuiSession(identity, mode, Number("pid", 0));
                    var captureService = new CaptureService(_adbService, _settingsService, _settings, _logService);
                    var captured = await Task.Run(() => captureService.ProcessCapturedFile(capturePath, "DXM", captureSession.serial), token);
                    return new { message = "Capture saved. / 캡처를 저장했습니다.", path = captured.LocalPath, remotePath = captured.RemotePath, transferred = captured.TransferredToDevice };
                }
                catch (Exception ex) when (ex is not OperationCanceledException)
                {
                    throw new InvalidOperationException($"Saved on Mac: {capturePath}\n휴대폰 전송은 완료하지 못했습니다. / Phone transfer did not complete.\n{ex.Message}", ex);
                }
            case "key-input":
                var inputSession = RequireGuiSession(identity, mode, Number("pid", 0));
                if (inputSession.displayId <= 0) throw new InvalidOperationException("The managed display is not ready for ADB input.");
                var input = Text("key") switch { "hangul" => "keycombination -t 20 59 62", "enter" => "keycombination -t 20 59 66", _ => throw new ArgumentException("Unknown key action.") };
                var inputResult = await Task.Run(() => _adbService.ShellForSerial(inputSession.serial, $"input -d {inputSession.displayId} {input}", false), token);
                if (!inputResult.IsSuccess) throw new InvalidOperationException("ADB key input failed. / ADB 키 입력에 실패했습니다.");
                return new { message = "" };
            case "session-stop":
                RequireOwnedGuiSession(identity, mode, Number("pid", 0));
                goto case "stop";
            case "save":
                var value = request.GetProperty("run").Deserialize<GuiRunSettings>(GuiProtocol.Json);
                value.Validate(mode);
                if (mode == 0 && _guiRuntimes.TryGetValue(identity, out var savingRuntime) && savingRuntime.Dex.IsRunning &&
                    value.HidePhonePreview != _runSettings.GetSnapshot(identity).VirtualDisplay.HidePhonePreview)
                    throw new InvalidOperationException("Stop DeX before changing phone-preview hiding. / 휴대폰 미리보기 숨김은 DeX를 중지한 뒤 바꿀 수 있습니다.");
                _runSettings.UpdateAndSave(identity, p => value.Apply(p, mode));
                return new { message = "Settings saved. / 설정을 저장했습니다." };
            case "general":
                var language = Number("language", 0); var theme = Number("theme", 0);
                var delay = Number("startDelay", 1); var hideDelay = Number("hideDelay", 30);
                if (language is < 0 or > 2 || theme is < 0 or > 2 || delay is < 0 or > 60 || hideDelay is < 1 or > 3600)
                    throw new ArgumentException("Invalid settings value.");
                var send = Text("send"); var receive = Text("receive");
                if (!send.StartsWith("/sdcard/", StringComparison.Ordinal) || send.Contains('\n') || send.Contains('\0'))
                    throw new ArgumentException("The phone destination must be under /sdcard/. / 휴대폰 폴더는 /sdcard/ 아래로 지정하세요.");
                if (!Path.IsPathFullyQualified(receive)) throw new ArgumentException("Choose an absolute Mac receive folder.");
                _settingsService.UpdateAndSave(_settings, s =>
                {
                    s.Language = (AppLanguage)language; s.Theme = (AppTheme)theme;
                    s.Features.AutoStartDexOnDeviceConnected = Flag("autoStart");
                    s.Timing.ConnectedStartDelayMs = delay * 1000;
                    s.Features.AutoHideEnabled = Flag("autoHide"); s.Timing.AutoHideIdleSeconds = hideDelay;
                    s.Features.StartMinimizedToTray = Flag("startMinimized");
                    s.Features.ManagedFileTransferEnabled = Flag("managedTransfer");
                    s.Features.PhoneToPcTransferEnabled = Flag("phoneTransfer");
                    s.Features.DisableStayAwakeOnStop = Flag("restoreAwake");
                    s.Paths.FileTransferTargetFolder = send; s.Paths.PhoneToPcReceiveFolder = receive;
                });
                _autoStartService.Apply(Flag("login"));
                LocalizationService.Apply(_settings.Language);
                foreach (var r in _guiRuntimes.Values) r.PhoneTransfers.ApplySettings();
                return new { message = "Settings saved. / 설정을 저장했습니다." };
            case "start":
                var device = RequireGuiDevice(identity);
                var serial = device.SelectPreferredTransport(null).Serial;
                var runtime = GuiRuntime(identity);
                runtime.Scrcpy.DeviceDisplayName = device.DisplayName;
                runtime.SingleWindows.DeviceDisplayName = device.DisplayName;
                if (mode == 0)
                {
                    if (!await runtime.Dex.StartAsync(serial, identity, token))
                        throw new InvalidOperationException("DeX could not start; check the session log. / 세션 로그를 확인하세요.");
                }
                else
                {
                    var slot = _runSettings.GetSnapshot(identity).SingleWindowSlots.Single(x => x.Slot == mode);
                    GuiRunSettings.Read(_runSettings.GetSnapshot(identity), mode).Validate(mode);
                    runtime.SingleWindows.Start(mode, slot, serial);
                    if (!runtime.SingleWindows.IsRunning(mode)) throw new InvalidOperationException("The app window did not start.");
                }
                if (_settings.Features.PhoneToPcTransferEnabled) await runtime.PhoneTransfers.AttachAsync(serial, device.DisplayName);
                return new { message = "Started. / 실행했습니다." };
            case "stop":
                if (_guiRuntimes.TryGetValue(identity, out var stopping))
                {
                    if (mode == 0 && !await stopping.Dex.StopOrConfirmCleanupAsync())
                        throw new InvalidOperationException("Stopped; display cleanup is waiting for this device to reconnect. / 기기가 다시 연결되면 화면 정리를 확인해야 합니다.");
                    if (mode != 0) stopping.SingleWindows.Stop(mode);
                }
                return new { message = "Stopped. / 중지했습니다." };
            case "apps":
                var appDevice = RequireGuiDevice(identity);
                return GuiRuntime(identity).Scrcpy.ListApps(appDevice.SelectPreferredTransport(null).Serial);
            case "profile-save":
            case "profile-load":
            case "profile-auto":
            case "profile-delete":
                if (mode == 0) throw new ArgumentException("App profiles apply to single-window slots.");
                _runSettings.UpdateAndSave(identity, profile =>
                {
                    var slot = profile.SingleWindowSlots.Single(x => x.Slot == mode);
                    if (string.IsNullOrEmpty(slot.StartAppPackage)) throw new ArgumentException("Select an app first.");
                    var saved = profile.SingleWindowAppProfiles.FirstOrDefault(x => x.PackageName == slot.StartAppPackage);
                    if (command is "profile-load" or "profile-auto")
                    {
                        if (saved == null)
                        {
                            if (command == "profile-auto") return;
                            throw new InvalidOperationException("No saved app profile. / 저장한 앱 설정이 없습니다.");
                        }
                        var restored = GuiRunSettings.Convert<SingleWindowSlotSettings>(saved);
                        restored.Slot = mode; restored.StartAppPackage = saved.PackageName; restored.StartAppName = saved.AppName;
                        profile.SingleWindowSlots[profile.SingleWindowSlots.FindIndex(x => x.Slot == mode)] = restored;
                    }
                    else
                    {
                        if (saved != null) profile.SingleWindowAppProfiles.Remove(saved);
                        if (command == "profile-save")
                        {
                            var savedProfile = GuiRunSettings.Convert<SingleWindowAppProfile>(slot);
                            savedProfile.PackageName = slot.StartAppPackage; savedProfile.AppName = slot.StartAppName;
                            profile.SingleWindowAppProfiles.Add(savedProfile);
                        }
                    }
                });
                return new { message = "App profile updated. / 앱 설정을 반영했습니다." };
            case "wireless-connect":
            case "wireless-prepare":
            case "wireless-disconnect":
            case "wireless-pair":
                WirelessConnectionResult connection;
                var port = Number("port", 5555);
                if (command == "wireless-pair") connection = _wirelessAdb.Pair(Text("host"), port, Text("code"));
                else if (command == "wireless-connect") connection = string.IsNullOrEmpty(identity)
                    ? _wirelessAdb.Connect(Text("host"), port)
                    : _wirelessAdb.ConnectForDevice(identity, Text("host"), port, Flag("reconnect"));
                else if (command == "wireless-prepare")
                {
                    var usb = RequireGuiDevice(identity).SelectAuthorizedTransport(DeviceTransportKind.Usb, null);
                    if (usb == null) throw new InvalidOperationException("Select a USB-connected device.");
                    connection = _wirelessAdb.EnableFromUsbForDevice(identity, usb.Serial, Text("host"), port, Flag("reconnect"));
                }
                else
                {
                    if (string.IsNullOrEmpty(identity)) throw new ArgumentException("Select a device to disconnect.");
                    connection = _wirelessAdb.DisconnectForDevice(identity);
                }
                if (!connection.Success) throw new InvalidOperationException(connection.Message);
                return new { message = connection.Message, endpoint = connection.Endpoint };
            case "cancel-transfer":
                if (_guiRuntimes.TryGetValue(identity, out var cancelRuntime))
                    cancelRuntime.FileTransfers.CancelTransfer(Text("requestId"));
                return new { message = "Cancellation requested. / 전송 취소를 요청했습니다." };
            case "send":
                var transferDevice = RequireGuiDevice(identity);
                var path = Text("path");
                if (!File.Exists(path) && !Directory.Exists(path)) throw new FileNotFoundException("Select an existing file or folder.");
                var result = _adbService.PushForSerial(transferDevice.SelectPreferredTransport(null).Serial, path, _settings.Paths.FileTransferTargetFolder);
                if (!result.IsSuccess) throw new IOException(result.StandardError);
                return new { message = "Transfer complete. / 파일 전송을 마쳤습니다." };
            case "companion-inspect":
            case "companion-install":
            case "companion-grant":
            case "companion-uninstall":
                var companionSerial = RequireGuiDevice(identity).SelectPreferredTransport(null).Serial;
                if (command == "companion-uninstall" && _guiRuntimes.TryGetValue(identity, out var companionRuntime))
                {
                    companionRuntime.FileTransfers.CancelSerial(companionSerial);
                    await companionRuntime.PhoneTransfers.DetachAsync(companionSerial);
                }
                var status = command switch
                {
                    "companion-install" => _permissionService.InstallAndGrant(companionSerial),
                    "companion-grant" => _permissionService.Grant(companionSerial),
                    "companion-uninstall" => _permissionService.Uninstall(companionSerial),
                    _ => _permissionService.Inspect(companionSerial)
                };
                return new { message = $"{status.State}: {status.Detail}", bundled = _permissionService.InspectBundledApk().State.ToString() };
            case "diagnostics":
                _selectedDeviceIdentity = identity;
                _selectedDeviceSerial = GuiDevice(identity)?.SelectPreferredTransport(null)?.Serial;
                return new { text = string.Join("\n\n", _envCheckService.Run().Select(x => $"{x.Name}: {x.Status}\n{x.Message}")) };
            case "logs": return new { text = string.Join("\n", _logService.GetSessionEntries().TakeLast(150)) };
            default: throw new ArgumentException("Unknown GUI command.");
        }
    }

    internal async Task ShutdownGuiAsync()
    {
        _deviceMonitor.RequestShutdown();
        foreach (var pair in _guiRuntimes)
        {
            var runtime = pair.Value;
            try
            {
                runtime.FileTransfers.RequestShutdown(); runtime.PhoneTransfers.RequestShutdown();
                runtime.CompanionGuardian.RequestShutdown(); runtime.ScreenOff.RequestShutdown();
                runtime.SingleWindows.RequestShutdown(); runtime.Dex.RequestShutdown();
                runtime.SingleWindows.StopAll();
                var serial = GuiDevice(pair.Key)?.SelectPreferredTransport(null)?.Serial ?? runtime.Dex.CurrentSession?.Serial;
                // ListApps also creates a service bundle. Never use the TUI's
                // untracked-overlay shutdown fallback merely because a bundle exists.
                // Stop/retry only leases actually owned by this GUI runtime.
                if (!await runtime.Dex.StopOrConfirmCleanupAsync() && !string.IsNullOrEmpty(serial))
                    await runtime.Dex.RetryDeferredCleanupAsync(serial, pair.Key);
                if (!runtime.Dex.IsCleanupComplete)
                    _logService.Warning("GUI display cleanup deferred until the selected device reconnects.");
            }
            catch (Exception ex) { _logService.Error("GUI session cleanup failed.", ex); }
            foreach (var service in new IDisposable[] { runtime.SingleWindows, runtime.Scrcpy, runtime.ScreenOff,
                runtime.PhoneTransfers, runtime.CompanionGuardian, runtime.FileTransfers })
            {
                try { service.Dispose(); }
                catch (Exception ex) { _logService.Error("GUI service disposal failed.", ex); }
            }
        }
        _guiRuntimes.Clear();
    }
}
