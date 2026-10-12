using System.Text.Json;
using System.Threading.Channels;
using DexManager.Mac.Hosting;

namespace DexManager.Tests;

public sealed class GuiProtocolTests
{
    private sealed class Input : TextReader
    {
        internal readonly Channel<string> Lines = Channel.CreateUnbounded<string>();
        public override async ValueTask<string> ReadLineAsync(CancellationToken cancellationToken)
        {
            return await Lines.Reader.WaitToReadAsync(cancellationToken) ? await Lines.Reader.ReadAsync(cancellationToken) : null;
        }
    }

    private sealed class Output : StringWriter
    {
        internal readonly Channel<string> Lines = Channel.CreateUnbounded<string>();
        public override Task WriteLineAsync(string value)
        {
            Lines.Writer.TryWrite(value);
            return base.WriteLineAsync(value);
        }
    }

    [Fact]
    public async Task EOFInterruptsAnInFlightLaunchAndRunsCleanupExactlyOnce()
    {
        var input = new Input(); var output = new Output(); var started = new TaskCompletionSource(); int cleanups = 0;
        var serving = GuiProtocol.ServeAsync(input, output, async (_, request, token) =>
        {
            Assert.Equal("phone-a", request.GetProperty("device").GetString());
            started.SetResult(); await Task.Delay(Timeout.Infinite, token); return null;
        }, () => { cleanups++; return Task.CompletedTask; }, CancellationToken.None);
        input.Lines.Writer.TryWrite("{\"id\":\"1\",\"command\":\"start\",\"device\":\"phone-a\"}");
        await started.Task.WaitAsync(TimeSpan.FromSeconds(3)); input.Lines.Writer.Complete();
        Assert.Equal(0, await serving.WaitAsync(TimeSpan.FromSeconds(3))); Assert.Equal(1, cleanups);
    }

    [Fact]
    public async Task ErrorsAreFramedAndDoNotPreventLaterCommandsOrExplicitQuit()
    {
        var input = new Input(); var output = new Output(); int cleanups = 0;
        var serving = GuiProtocol.ServeAsync(input, output, (command, _, _) =>
        {
            if (command == "bad") throw new InvalidOperationException("test error");
            return Task.FromResult<object>(new { value = 42 });
        }, () => { cleanups++; return Task.CompletedTask; }, CancellationToken.None);
        input.Lines.Writer.TryWrite("{\"id\":\"1\",\"command\":\"bad\"}");
        using var error = JsonDocument.Parse(await output.Lines.Reader.ReadAsync().AsTask().WaitAsync(TimeSpan.FromSeconds(3)));
        Assert.False(error.RootElement.GetProperty("ok").GetBoolean());
        Assert.Equal("1", error.RootElement.GetProperty("id").GetString());
        input.Lines.Writer.TryWrite("{\"id\":\"2\",\"command\":\"state\"}");
        using var success = JsonDocument.Parse(await output.Lines.Reader.ReadAsync().AsTask().WaitAsync(TimeSpan.FromSeconds(3)));
        Assert.True(success.RootElement.GetProperty("ok").GetBoolean());
        Assert.Equal(42, success.RootElement.GetProperty("data").GetProperty("value").GetInt32());
        input.Lines.Writer.TryWrite("{\"id\":\"3\",\"command\":\"quit\"}");
        Assert.Equal(0, await serving.WaitAsync(TimeSpan.FromSeconds(3))); Assert.Equal(1, cleanups);
    }
}
