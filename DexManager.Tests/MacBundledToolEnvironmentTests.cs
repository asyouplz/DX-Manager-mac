using DexManager.Mac;
using DexManager.Mac.Platform;

namespace DexManager.Tests;

public sealed class MacBundledToolEnvironmentTests
{
    [Fact]
    public void AppBundle_UsesResourceServerAndIconPaths()
    {
        var root = Path.Combine(Path.GetTempPath(), "dxm-app-env-" + Guid.NewGuid().ToString("N"));
        try
        {
            var paths = new MacPathProvider(null, Path.Combine(root, "한글 app.app", "Contents", "MacOS"), root);
            Directory.CreateDirectory(paths.BundledScrcpyResourceDirectory);
            File.WriteAllText(paths.BundledScrcpyServerPath, "test server payload");
            var environment = new Dictionary<string, string>();

            Program.ConfigureBundledScrcpyEnvironment(paths, (key, value) => environment[key] = value);

            Assert.Equal(paths.BundledScrcpyServerPath, environment["SCRCPY_SERVER_PATH"]);
            Assert.Equal(paths.BundledScrcpyResourceDirectory, environment["SCRCPY_ICON_DIR"]);
            Assert.Equal(2, environment.Count);
        }
        finally
        {
            if (Directory.Exists(root)) Directory.Delete(root, true);
        }
    }

    [Fact]
    public void PortableFolder_DoesNotChangeScrcpyEnvironmentOverrides()
    {
        var paths = new MacPathProvider(true, Path.GetTempPath());
        var environment = new Dictionary<string, string> { ["SCRCPY_SERVER_PATH"] = "user-custom-server" };

        Program.ConfigureBundledScrcpyEnvironment(paths, (key, value) => environment[key] = value);

        Assert.Single(environment);
        Assert.Equal("user-custom-server", environment["SCRCPY_SERVER_PATH"]);
    }

    [Fact]
    public void MissingAppServer_FailsBeforeChangingEnvironment()
    {
        var root = Path.Combine(Path.GetTempPath(), "dxm-app-env-missing-" + Guid.NewGuid().ToString("N"));
        var paths = new MacPathProvider(null, Path.Combine(root, "DX Manager.app", "Contents", "MacOS"), root);
        var environment = new Dictionary<string, string>();

        Assert.Throws<FileNotFoundException>(() => Program.ConfigureBundledScrcpyEnvironment(
            paths, (key, value) => environment[key] = value));
        Assert.Empty(environment);
    }
}
