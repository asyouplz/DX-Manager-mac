#import <AppKit/AppKit.h>
#import "GuiApp.h"

static int runTool(NSString *executable, NSArray<NSString *> *arguments, NSString **output) {
    NSTask *task = [[NSTask alloc] init];
    task.executableURL = [NSURL fileURLWithPath:executable];
    task.arguments = arguments;
    NSPipe *pipe = nil;
    if (output != NULL) {
        pipe = [NSPipe pipe];
        task.standardOutput = pipe;
        task.standardError = pipe;
    }
    NSError *error = nil;
    if (![task launchAndReturnError:&error]) {
        if (output != NULL) *output = error.localizedDescription;
        return 1;
    }
    NSData *data = output != NULL ? [pipe.fileHandleForReading readDataToEndOfFile] : nil;
    [task waitUntilExit];
    if (output != NULL) *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
    return task.terminationStatus;
}

static void showFailure(NSString *message) {
    [NSApplication sharedApplication];
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"DX Manager could not start / DX Manager를 시작할 수 없습니다";
    alert.informativeText = message;
    [alert addButtonWithTitle:@"OK / 확인"];
    [alert runModal];
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *appPath = bundle.bundlePath;
        NSString *macOSPath = [appPath stringByAppendingPathComponent:@"Contents/MacOS"];
        NSString *mode = argc > 1 ? [NSString stringWithUTF8String:argv[1]] : nil;
        if (mode != nil && ![@[@"--verify", @"--version", @"--help"] containsObject:mode]) {
            fprintf(stderr, "Use --verify, --version, or --help; open the app without arguments for the graphical interface.\n");
            return 2;
        }

        NSString *verificationOutput = nil;
        int result = runTool(@"/usr/bin/codesign", @[@"--verify", @"--deep", @"--strict", appPath], &verificationOutput);
        NSFileManager *files = [NSFileManager defaultManager];
        for (NSString *relativePath in @[@"DXManager.Mac", @"tools/adb-proxy/DXMAdbProxy", @"tools/scrcpy/scrcpy", @"tools/scrcpy/adb"]) {
            if (![files isExecutableFileAtPath:[macOSPath stringByAppendingPathComponent:relativePath]]) {
                result = 1;
                verificationOutput = @"A bundled executable is missing or not executable.";
                break;
            }
        }
        if (result != 0) {
            NSString *message = @"The app's integrity check failed. Download and extract the complete package again. Do not replace files inside the app.\n\n앱 무결성 검사에 실패했습니다. 전체 패키지를 다시 내려받아 압축을 풀어 주세요. 앱 내부 파일을 교체하지 마십시오.";
            fprintf(stderr, "%s\n%s\n", message.UTF8String, verificationOutput.UTF8String);
            if (mode == nil) showFailure(message);
            return 1;
        }
        if ([mode isEqualToString:@"--verify"]) {
            puts("DX Manager app bundle integrity verified (ad-hoc signature; not notarized).");
            return 0;
        }
        if (mode != nil) {
            return runTool([macOSPath stringByAppendingPathComponent:@"DXManager.Mac"], @[mode], NULL);
        }

        return DXRunApplication([macOSPath stringByAppendingPathComponent:@"DXManager.Mac"]);
    }
}
