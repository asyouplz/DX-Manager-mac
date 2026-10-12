using System.Xml.Linq;
using DexManager.Platform;

namespace DexManager.Mac.Platform;

public sealed class MacAutoStartService : IAutoStartService
{
    private const string PlistFileName = "io.github.mazemei.dxmanager.plist";
    private static string PlistPath => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
        "Library", "LaunchAgents", PlistFileName);

    public bool IsRegistered() => File.Exists(PlistPath);
    public void Apply(bool enabled)
    {
        // Do not rewrite an existing user's login item on every unrelated save.
        if (enabled == IsRegistered()) return;
        if (enabled) Register(); else Unregister();
    }
    public void Register()
    {
        var launcher = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "DXManager.Launcher");
        if (!File.Exists(launcher)) throw new InvalidOperationException("Open the .app to enable login startup.");
        if (launcher.Contains("/AppTranslocation/", StringComparison.Ordinal))
            throw new InvalidOperationException("Move the whole app to Applications and reopen it before enabling login startup. / 앱을 응용 프로그램 폴더로 옮겨 다시 연 뒤 자동 실행을 설정하세요.");
        Directory.CreateDirectory(Path.GetDirectoryName(PlistPath));
        var plist = new XDocument(new XDeclaration("1.0", "UTF-8", null),
            new XDocumentType("plist", "-//Apple//DTD PLIST 1.0//EN", "http://www.apple.com/DTDs/PropertyList-1.0.dtd", null),
            new XElement("plist", new XAttribute("version", "1.0"), new XElement("dict",
                new XElement("key", "Label"), new XElement("string", "io.github.mazemei.dxmanager"),
                new XElement("key", "ProgramArguments"), new XElement("array", new XElement("string", launcher)),
                new XElement("key", "RunAtLoad"), new XElement("true"))));
        plist.Save(PlistPath);
    }
    public void Unregister() { if (File.Exists(PlistPath)) File.Delete(PlistPath); }
}
