using DexManager.Mac.Hosting;
using DexManager.Models;
using DexManager.Services;
namespace DexManager.Tests;
public sealed class GuiDesktopSettingsTests : IDisposable
{
    private readonly string folder=Path.Combine(Path.GetTempPath(),"dxm-desktop-tests-"+Guid.NewGuid());
    [Fact] public void SaveReloadKeepsDesktopSettingsAndDeviceProfilesSeparate()
    {
        var service=new SettingsService(new LogService(),folder);var settings=AppSettings.CreateDefault();
        settings.GetOrCreateDeviceRunSettings("phone-a").VirtualDisplay.Width=2560;
        var d=GuiDesktopSettings.Read(settings,Path.Combine(folder,"captures"));
        d.Enter=true;d.MiniSide=1;d.CaptureHotkey="Ctrl+F9";d.PushCapture=false;
        service.UpdateAndSave(settings,d.Apply);var loaded=service.Load();
        Assert.True(loaded.KeyMappings.ConvertEnterToShiftEnter);Assert.Equal(MiniControlBarSide.Left,loaded.Features.MiniControlBarSide);
        Assert.False(loaded.Features.PushCaptureToDevice);Assert.Equal(2560,loaded.GetOrCreateDeviceRunSettings("phone-a").VirtualDisplay.Width);
    }
    [Theory] [InlineData("LeftAlt+F8","Option+F8")] [InlineData("Ctrl + Shift + F12","Shift+Control+F12")]
    public void EquivalentShortcutsConflict(string a,string b)
    {var d=new GuiDesktopSettings {ScreenshotFolder=folder,CaptureHotkey=a,ExitHotkey=b};Assert.Throws<ArgumentException>(d.Validate);}
    [Theory] [InlineData("Cmd+Q")] [InlineData("F21")] [InlineData("Ctrl+Ctrl+F8")] [InlineData("Meta+F8")]
    public void RejectsUnsupportedShortcut(string shortcut)
    {Assert.Throws<ArgumentException>(()=>GuiDesktopSettings.NormalizeShortcut(shortcut));}
    [Fact] public void FailedValidationPreservesSettingsFileAndCurrentOptions()
    {
        var service=new SettingsService(new LogService(),folder);var settings=AppSettings.CreateDefault();service.Save(settings);
        var before=File.ReadAllBytes(service.SettingsFilePath);var d=GuiDesktopSettings.Read(settings,folder);d.CaptureWait=0;d.Enter=true;
        Assert.Throws<ArgumentException>(()=>service.UpdateAndSave(settings,d.Apply));Assert.Equal(before,File.ReadAllBytes(service.SettingsFilePath));Assert.False(settings.KeyMappings.ConvertEnterToShiftEnter);
    }
    [Fact] public void CaptureFinalizationRejectsForeignFileAndAcceptsOwnedPng()
    {
        Directory.CreateDirectory(folder);string name="DXM_"+Guid.NewGuid()+".png";string path=Path.Combine(folder,name);
        File.WriteAllBytes(path,new byte[]{137,80,78,71,13,10,26,10});GuiDesktopSettings.ValidateCaptureFile(path,folder);
        Assert.Throws<ArgumentException>(()=>GuiDesktopSettings.ValidateCaptureFile(path,Path.Combine(folder,"other")));
        File.WriteAllText(path,"not an image");Assert.Throws<ArgumentException>(()=>GuiDesktopSettings.ValidateCaptureFile(path,folder));
    }
    public void Dispose(){if(Directory.Exists(folder))Directory.Delete(folder,true);}
}
