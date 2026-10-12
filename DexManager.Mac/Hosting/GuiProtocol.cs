using System.Text.Json;
using System.Threading.Channels;

namespace DexManager.Mac.Hosting;

internal static class GuiProtocol
{
    internal static readonly JsonSerializerOptions Json = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true
    };

    internal static async Task<int> RunAsync(TextReader input, TextWriter output, CancellationToken cancellationToken)
    {
        Console.SetOut(Console.Error); // stdout is reserved for framed replies.
        var dataHome = Environment.GetEnvironmentVariable("DXM_GUI_DATA_HOME");
        if (!string.IsNullOrEmpty(dataHome) && !Path.IsPathFullyQualified(dataHome))
            throw new ArgumentException("DXM_GUI_DATA_HOME must be an absolute test home.");
        var paths = new Platform.MacPathProvider(null, userHome: dataHome);
        Directory.CreateDirectory(paths.SettingsDirectory);
        using var instanceLock = new FileStream(Path.Combine(paths.SettingsDirectory, ".gui-instance.lock"),
            FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None);
        using var host = new InteractiveHost(paths);
        host.StartGuiMonitor();
        return await ServeAsync(input, output, host.ExecuteGuiAsync, async () =>
        {
            await host.ShutdownGuiAsync();
            await host.ShutdownAsync();
        }, cancellationToken);
    }

    internal static async Task<int> ServeAsync(TextReader input, TextWriter output,
        Func<string, JsonElement, CancellationToken, Task<object>> execute, Func<Task> cleanup,
        CancellationToken cancellationToken)
    {
        using var lifetime = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        var commands = Channel.CreateBounded<string>(8);
        var reader = Task.Run(async () =>
        {
            try
            {
                while (await input.ReadLineAsync(lifetime.Token) is { } line)
                {
                    if (line.Length > 65536) break;
                    await commands.Writer.WriteAsync(line, lifetime.Token);
                }
            }
            catch (OperationCanceledException) { }
            catch (IOException) { }
            finally { commands.Writer.TryComplete(); lifetime.Cancel(); }
        }, CancellationToken.None);
        try
        {
            await foreach (var line in commands.Reader.ReadAllAsync(lifetime.Token))
            {
                string id = "";
                try
                {
                    using var document = JsonDocument.Parse(line);
                    var request = document.RootElement;
                    id = request.GetProperty("id").GetString() ?? "";
                    var command = request.GetProperty("command").GetString();
                    if (command == "quit") break;
                    var data = await execute(command, request, lifetime.Token);
                    await output.WriteLineAsync(JsonSerializer.Serialize(new { id, ok = true, data }, Json));
                }
                catch (OperationCanceledException) when (lifetime.IsCancellationRequested) { break; }
                catch (Exception ex)
                {
                    await output.WriteLineAsync(JsonSerializer.Serialize(new { id, ok = false, error = ex.Message }, Json));
                }
                await output.FlushAsync();
            }
        }
        catch (OperationCanceledException) { }
        finally
        {
            lifetime.Cancel();
            await cleanup();
            await reader;
        }
        return 0;
    }
}
