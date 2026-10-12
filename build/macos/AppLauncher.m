#import <AppKit/AppKit.h>

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
        NSString *commandPath = [appPath stringByAppendingPathComponent:@"Contents/Resources/Start DX Manager.command"];
        NSString *mode = argc > 1 ? [NSString stringWithUTF8String:argv[1]] : nil;
        if (mode != nil && ![@[@"--verify", @"--version", @"--help"] containsObject:mode]) {
            fprintf(stderr, "Use --verify, --version, or --help; open the app without arguments for the terminal menu.\n");
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
        if (![files isExecutableFileAtPath:commandPath]) {
            result = 1;
            verificationOutput = @"The bundled terminal launcher is missing or not executable.";
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

        // Opening the command file uses Launch Services, not Terminal AppleEvents;
        // no Automation permission or quarantine changes are required by this launcher.
        NSURL *terminalURL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:@"com.apple.Terminal"];
        if (terminalURL == nil) {
            showFailure(@"Terminal could not be found.\n\nTerminal 앱을 찾을 수 없습니다.");
            return 1;
        }
        NSWorkspaceOpenConfiguration *configuration = [NSWorkspaceOpenConfiguration configuration];
        __block BOOL finished = NO;
        __block NSError *openError = nil;
        [[NSWorkspace sharedWorkspace] openURLs:@[[NSURL fileURLWithPath:commandPath]]
                          withApplicationAtURL:terminalURL
                                 configuration:configuration
                             completionHandler:^(NSRunningApplication *application, NSError *error) {
            (void)application;
            openError = error;
            finished = YES;
        }];
        while (!finished) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
        }
        if (openError != nil) {
            showFailure(@"macOS could not open the terminal launcher. If it was blocked, review System Settings > Privacy & Security > Open Anyway for this app. Approval may also be required for a bundled component.\n\nmacOS가 터미널 실행기를 열지 못했습니다. 차단된 경우 시스템 설정 > 개인정보 보호 및 보안에서 이 앱의 '그래도 열기'를 확인하십시오. 포함된 구성요소도 별도 승인이 필요할 수 있습니다.");
            return 1;
        }
        return 0;
    }
}
