#import "GuiApp.h"
#import "DXDesktopControls.h"

static NSInteger DXLanguage = 0;
static NSString *L(NSString *en, NSString *ko) {
    BOOL korean = DXLanguage == 1 || (DXLanguage == 0 && [NSLocale.preferredLanguages.firstObject hasPrefix:@"ko"]);
    return korean ? ko : en;
}
static NSString *S(id value) { return [value isKindOfClass:NSString.class] ? value : @""; }
static BOOL B(id value) { return [value respondsToSelector:@selector(boolValue)] && [value boolValue]; }

typedef void (^DXReply)(id data, NSString *error);
@interface DXBridge : NSObject
@property NSTask *task;
@property NSFileHandle *input;
@property NSMutableDictionary<NSString *, DXReply> *pending;
@property NSUInteger sequence;
@property(copy) void (^exited)(int);
- (BOOL)start:(NSString *)path error:(NSError **)error;
- (void)send:(NSString *)command fields:(NSDictionary *)fields reply:(DXReply)reply;
@end
@implementation DXBridge
- (BOOL)start:(NSString *)path error:(NSError **)error {
    self.pending = [NSMutableDictionary dictionary];
    self.task = [[NSTask alloc] init]; self.task.executableURL = [NSURL fileURLWithPath:path];
    self.task.arguments = @[@"--gui-host"];
    NSPipe *inPipe = NSPipe.pipe, *outPipe = NSPipe.pipe, *errPipe = NSPipe.pipe;
    self.task.standardInput = inPipe; self.task.standardOutput = outPipe; self.task.standardError = errPipe;
    self.input = inPipe.fileHandleForWriting;
    __weak DXBridge *weak = self;
    self.task.terminationHandler = ^(NSTask *task) {
        dispatch_async(dispatch_get_main_queue(), ^{
            DXBridge *strong = weak;
            NSArray *callbacks = strong.pending.allValues.copy;
            [strong.pending removeAllObjects];
            for (DXReply reply in callbacks) reply(nil, L(@"The device service stopped. Reopen DX Manager.", @"기기 서비스가 종료됐습니다. DX Manager를 다시 열어 주세요."));
            if (strong.exited) strong.exited(task.terminationStatus);
        });
    };
    if (![self.task launchAndReturnError:error]) return NO;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        @autoreleasepool {
            NSMutableData *buffer = [NSMutableData data];
            while (YES) { @autoreleasepool {
                NSData *chunk = [outPipe.fileHandleForReading availableData];
                if (!chunk.length) break;
                [buffer appendData:chunk];
                if (buffer.length > 8 * 1024 * 1024) { [inPipe.fileHandleForWriting closeFile]; break; }
                while (YES) {
                    const unsigned char *bytes = buffer.bytes;
                    const unsigned char *newline = memchr(bytes, '\n', buffer.length);
                    if (!newline) break;
                    NSUInteger length = (NSUInteger)(newline - bytes);
                    NSData *line = [buffer subdataWithRange:NSMakeRange(0, length)];
                    [buffer replaceBytesInRange:NSMakeRange(0, length + 1) withBytes:NULL length:0];
                    NSDictionary *frame = [NSJSONSerialization JSONObjectWithData:line options:0 error:NULL];
                    if (![frame isKindOfClass:NSDictionary.class]) continue;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        DXBridge *strong = weak; NSString *key = S(frame[@"id"]);
                        DXReply reply = strong.pending[key]; [strong.pending removeObjectForKey:key];
                        if (reply) reply(frame[@"data"], B(frame[@"ok"]) ? nil : S(frame[@"error"]));
                    });
                }
            } }
        }
    });
    // Drain diagnostics independently so a verbose scrcpy/ADB failure cannot block IPC.
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        while (YES) { @autoreleasepool { if (![errPipe.fileHandleForReading availableData].length) break; } }
    });
    return YES;
}
- (void)send:(NSString *)command fields:(NSDictionary *)fields reply:(DXReply)reply {
    NSString *key = [NSString stringWithFormat:@"%lu", (unsigned long)++self.sequence];
    NSMutableDictionary *request = [fields mutableCopy] ?: [NSMutableDictionary dictionary];
    request[@"command"] = command; request[@"id"] = key;
    NSError *error; NSData *json = [NSJSONSerialization dataWithJSONObject:request options:0 error:&error];
    if (!json || !self.task.running) { if (reply) reply(nil, error.localizedDescription ?: L(@"Device service is unavailable.", @"기기 서비스에 연결할 수 없습니다.")); return; }
    if (reply) self.pending[key] = [reply copy];
    NSMutableData *data = [json mutableCopy]; [data appendBytes:"\n" length:1];
    @try { [self.input writeData:data]; }
    @catch (NSException *exception) { [self.pending removeObjectForKey:key]; if (reply) reply(nil, exception.reason); }
}
@end

@interface DXFlippedView : NSView
@property NSColor *fillColor;
@end
@implementation DXFlippedView
- (BOOL)isFlipped { return YES; }
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    if (self.fillColor) {
        [self.fillColor setFill];
        [[NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:12 yRadius:12] fill];
    }
}
- (void)viewDidChangeEffectiveAppearance {
    [super viewDidChangeEffectiveAppearance]; self.needsDisplay = YES;
}
@end

@interface DXApp : NSObject <NSApplicationDelegate, NSWindowDelegate, NSTextFieldDelegate>
@property NSString *executable;
@property DXBridge *bridge;
@property DXDesktopControls *desktop;
@property NSTextField *permissionLabel;
@property NSWindow *window;
@property NSMutableArray<NSWindow *> *auxiliaryWindows;
@property DXFlippedView *root;
@property DXFlippedView *pane;
@property DXFlippedView *footer;
@property NSMutableArray<NSButton *> *navigationButtons;
@property NSPopUpButton *deviceBox;
@property NSTextField *status;
@property NSTextField *detail;
@property NSTextField *message;
@property NSProgressIndicator *progress;
@property NSMutableDictionary<NSString *, NSControl *> *fields;
@property NSMutableArray<NSControl *> *actions;
@property NSArray<NSDictionary *> *devices;
@property NSDictionary *settings;
@property NSDictionary *transfer;
@property NSDictionary *receive;
@property NSTextField *transferLabel;
@property NSArray<NSDictionary *> *apps;
@property NSString *identity;
@property NSInteger mode;
@property NSInteger page;
@property BOOL busy;
@property BOOL polling;
@property BOOL closing;
@property BOOL dirty;
@property NSTimer *timer;
@property NSDate *lastInteraction;
@property NSMutableSet<NSString *> *autoStarted;
@property NSButton *startButton;
@property NSButton *stopButton;
@end

@implementation DXApp
- (NSTextField *)label:(NSString *)text frame:(NSRect)frame font:(CGFloat)size parent:(NSView *)parent {
    NSTextField *field = [NSTextField wrappingLabelWithString:text ?: @""]; field.frame = frame;
    field.font = [NSFont systemFontOfSize:size]; [parent addSubview:field]; return field;
}
- (NSButton *)button:(NSString *)title action:(SEL)action frame:(NSRect)frame parent:(NSView *)parent {
    NSButton *button = [NSButton buttonWithTitle:title target:self action:action]; button.frame = frame;
    button.bezelStyle = NSBezelStyleRounded; [parent addSubview:button];
    [self.actions addObject:button]; return button;
}
- (DXFlippedView *)card:(NSString *)title y:(CGFloat)y height:(CGFloat)height {
    DXFlippedView *view = [[DXFlippedView alloc] initWithFrame:NSMakeRect(0, y, 690, height)];
    view.fillColor = NSColor.controlBackgroundColor;
    [self.pane addSubview:view];
    NSTextField *label = [self label:title frame:NSMakeRect(20, 14, 650, 24) font:16 parent:view];
    label.font = [NSFont boldSystemFontOfSize:16]; return view;
}
- (NSTextField *)text:(NSString *)key title:(NSString *)title x:(CGFloat)x y:(CGFloat)y width:(CGFloat)width parent:(NSView *)parent {
    [self label:title frame:NSMakeRect(x, y, width, 20) font:12 parent:parent];
    NSTextField *field = [[NSTextField alloc] initWithFrame:NSMakeRect(x, y + 23, width, 28)];
    field.delegate = self; field.accessibilityLabel = title; [parent addSubview:field]; self.fields[key] = field;
    return field;
}
- (NSButton *)check:(NSString *)key title:(NSString *)title x:(CGFloat)x y:(CGFloat)y parent:(NSView *)parent {
    NSButton *button = [NSButton checkboxWithTitle:title target:self action:@selector(edited:)];
    button.frame = NSMakeRect(x, y, 315, 26); [parent addSubview:button]; self.fields[key] = button; return button;
}
- (void)setText:(NSString *)key value:(id)value { ((NSTextField *)self.fields[key]).stringValue = [value respondsToSelector:@selector(stringValue)] ? [value stringValue] : S(value); }
- (void)setCheck:(NSString *)key value:(id)value { ((NSButton *)self.fields[key]).state = B(value) ? NSControlStateValueOn : NSControlStateValueOff; }
- (NSString *)textValue:(NSString *)key { return ((NSTextField *)self.fields[key]).stringValue ?: @""; }
- (BOOL)checkValue:(NSString *)key { return ((NSButton *)self.fields[key]).state == NSControlStateValueOn; }
- (void)edited:(id)sender { (void)sender; self.dirty = YES; self.lastInteraction = NSDate.date; }
- (void)controlTextDidChange:(NSNotification *)notification { [self edited:notification.object]; }

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    self.identity = @""; self.devices = @[]; self.apps = @[]; self.auxiliaryWindows = [NSMutableArray array];
    self.autoStarted = [NSMutableSet set]; self.lastInteraction = NSDate.date;
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [self buildMenu];
    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 944, 800)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable
        backing:NSBackingStoreBuffered defer:NO];
    self.window.title = @"DX Manager"; self.window.minSize = NSMakeSize(944, 700); self.window.delegate = self;
    self.window.releasedWhenClosed = NO; [self.window center]; [self buildShell];
    [self.window makeKeyAndOrderFront:nil]; [NSApp activateIgnoringOtherApps:YES];
    self.desktop = [[DXDesktopControls alloc] init];
    __weak DXApp *desktopOwner = self;
    self.desktop.message = ^(NSString *text) { desktopOwner.message.stringValue = text ?: @""; };
    self.desktop.showManager = ^{ [desktopOwner.window deminiaturize:nil]; [desktopOwner.window makeKeyAndOrderFront:nil]; [NSApp activateIgnoringOtherApps:YES]; };
    self.desktop.command = ^(NSString *command, NSDictionary *session, NSDictionary *fields) {
        DXApp *owner = desktopOwner; if (owner.closing) return;
        NSMutableDictionary *args=[fields mutableCopy]; args[@"device"]=session[@"device"]; args[@"mode"]=session[@"mode"]; args[@"pid"]=session[@"pid"];
        [owner.bridge send:command fields:args reply:^(id data, NSString *error) {
            if(error) { owner.message.stringValue=error; }
            else if([command isEqual:@"capture-finish"]) owner.message.stringValue=[NSString stringWithFormat:L(@"Saved: %@%@", @"저장: %@%@"),S(data[@"path"]),B(data[@"transferred"])?L(@" · copied to phone", @" · 휴대폰 전송 완료"):@""];
            [owner poll];
        }];
    };
    self.bridge = [[DXBridge alloc] init];
    __weak DXApp *weak = self;
    self.bridge.exited = ^(int status) {
        DXApp *strong = weak;
        if (strong.closing) { [NSApp replyToApplicationShouldTerminate:YES]; return; }
        strong.status.stringValue = L(@"Device service stopped", @"기기 서비스 종료");
        strong.detail.stringValue = [NSString stringWithFormat:L(@"Exit code %d. Reopen the app; see logs if it happens again.", @"종료 코드 %d. 앱을 다시 열어 주세요. 반복되면 로그를 확인하세요."), status];
        [strong.timer invalidate]; [strong.desktop stop]; [strong updateEnabled];
    };
    NSError *error;
    if (![self.bridge start:self.executable error:&error]) { [self showError:error.localizedDescription]; return; }
    [self loadSettings:^{
        [weak buildShell];
        if (B(weak.settings[@"general"][@"startMinimized"])) [weak.window miniaturize:nil];
        [weak poll];
    }];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(poll) userInfo:nil repeats:YES];
}
- (void)buildMenu {
    NSMenu *menu = [[NSMenu alloc] init]; NSMenuItem *appItem = [[NSMenuItem alloc] init]; [menu addItem:appItem];
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"DX Manager"]; appItem.submenu = appMenu;
    [appMenu addItemWithTitle:L(@"Settings…", @"설정…") action:@selector(showSettings:) keyEquivalent:@","].target = self;
    [appMenu addItem:NSMenuItem.separatorItem];
    [appMenu addItemWithTitle:L(@"Quit DX Manager", @"DX Manager 종료") action:@selector(terminate:) keyEquivalent:@"q"];
    NSMenuItem *editItem = [[NSMenuItem alloc] init]; [menu addItem:editItem];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:L(@"Edit", @"편집")]; editItem.submenu = editMenu;
    [editMenu addItemWithTitle:L(@"Cut", @"잘라내기") action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:L(@"Copy", @"복사") action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:L(@"Paste", @"붙여넣기") action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:L(@"Select All", @"전체 선택") action:@selector(selectAll:) keyEquivalent:@"a"];
    NSApp.mainMenu = menu;
}
- (void)buildShell {
    self.actions = [NSMutableArray array]; self.navigationButtons = [NSMutableArray array];
    self.root = [[DXFlippedView alloc] initWithFrame:NSMakeRect(0, 0, self.window.contentView.bounds.size.width, self.window.contentView.bounds.size.height)];
    self.root.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable; self.window.contentView = self.root;
    DXFlippedView *sidebar = [[DXFlippedView alloc] initWithFrame:NSMakeRect(14, 18, 190, self.root.bounds.size.height - 36)];
    sidebar.fillColor = NSColor.controlBackgroundColor; sidebar.autoresizingMask = NSViewHeightSizable;
    [self.root addSubview:sidebar];
    [self label:L(@"MODE", @"모드") frame:NSMakeRect(16, 18, 160, 20) font:11 parent:sidebar];
    NSArray *titles = @[@"DeX", L(@"Single window 1", @"단일창 1"), L(@"Single window 2", @"단일창 2"), L(@"Single window 3", @"단일창 3")];
    for (NSInteger i = 0; i < 4; i++) { NSButton *b = [self button:titles[i] action:@selector(navigate:) frame:NSMakeRect(8, 50 + i * 43, 174, 34) parent:sidebar]; b.tag = i; [b setButtonType:NSButtonTypePushOnPushOff]; [self.navigationButtons addObject:b]; }
    [self label:L(@"Each device and slot remembers its own settings.", @"기기와 슬롯마다 서로 다른 앱과 설정을 기억합니다.") frame:NSMakeRect(18, 235, 156, 58) font:12 parent:sidebar];
    [self label:L(@"SETTINGS", @"설정") frame:NSMakeRect(16, 300, 156, 20) font:11 parent:sidebar];
    NSArray *pages = @[L(@"General", @"기본"), L(@"Connection", @"연결"), L(@"Paths / Transfers", @"경로 / 파일 전송"), L(@"Keyboard", @"키 입력"), L(@"Diagnostics", @"진단 / Companion"), L(@"About", @"정보")];
    for (NSInteger i = 0; i < (NSInteger)pages.count; i++) { NSButton *b = [self button:pages[i] action:@selector(navigate:) frame:NSMakeRect(8, 332 + i * 39, 174, 34) parent:sidebar]; b.tag = i + 10; [b setButtonType:NSButtonTypePushOnPushOff]; [self.navigationButtons addObject:b]; }
    NSTextField *edition = [self label:@"macOS · 2.1.0" frame:NSMakeRect(18, sidebar.bounds.size.height - 40, 164, 22) font:11 parent:sidebar]; edition.autoresizingMask = NSViewMinYMargin;
    NSTextField *title = [self label:@"DX Manager" frame:NSMakeRect(224, 18, 370, 38) font:29 parent:self.root]; title.font = [NSFont boldSystemFontOfSize:29];
    self.deviceBox = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(588, 23, 332, 30) pullsDown:NO];
    self.deviceBox.target = self; self.deviceBox.action = @selector(selectDevice:); self.deviceBox.accessibilityLabel = L(@"Selected device", @"선택 기기"); [self.root addSubview:self.deviceBox]; [self rebuildDevices];
    self.status = [self label:L(@"Waiting for a device", @"휴대폰 연결 대기") frame:NSMakeRect(244, 79, 580, 28) font:21 parent:self.root]; self.status.font = [NSFont boldSystemFontOfSize:21];
    self.detail = [self label:L(@"Connect a Galaxy with USB debugging and approve its RSA prompt.", @"Galaxy의 USB 디버깅을 켜고 연결한 뒤 휴대폰에서 연결을 승인하세요.") frame:NSMakeRect(244, 112, 646, 44) font:12 parent:self.root];
    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(224, 171, 704, self.root.bounds.size.height - 267)];
    scroll.autoresizingMask = NSViewHeightSizable; scroll.hasVerticalScroller = YES; scroll.drawsBackground = NO;
    self.pane = [[DXFlippedView alloc] initWithFrame:NSMakeRect(0, 0, 690, 620)]; scroll.documentView = self.pane; [self.root addSubview:scroll];
    self.footer = [[DXFlippedView alloc] initWithFrame:NSMakeRect(224, self.root.bounds.size.height - 88, 690, 36)]; self.footer.autoresizingMask = NSViewMinYMargin; [self.root addSubview:self.footer];
    self.message = [self label:@"" frame:NSMakeRect(248, self.root.bounds.size.height - 52, 650, 44) font:12 parent:self.root]; self.message.autoresizingMask = NSViewMinYMargin;
    self.progress = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(223, self.root.bounds.size.height - 49, 18, 18)]; self.progress.style = NSProgressIndicatorStyleSpinning; self.progress.displayedWhenStopped = NO; self.progress.autoresizingMask = NSViewMinYMargin; [self.root addSubview:self.progress];
    [self renderPage];
}
- (void)rebuildDevices {
    [self.deviceBox removeAllItems]; [self.deviceBox addItemWithTitle:L(@"Default settings (no device)", @"공통 기본 설정 (기기 미선택)")]; self.deviceBox.lastItem.representedObject = @"";
    for (NSDictionary *device in self.devices) {
        [self.deviceBox addItemWithTitle:[NSString stringWithFormat:@"%@ · %@", S(device[@"name"]), S(device[@"transport"])]];
        self.deviceBox.lastItem.representedObject = device[@"identity"];
    }
    BOOL found = NO;
    for (NSMenuItem *item in self.deviceBox.itemArray) if ([item.representedObject isEqual:self.identity]) { [self.deviceBox selectItem:item]; found = YES; }
    if (!found && self.identity.length) {
        [self.deviceBox addItemWithTitle:L(@"Selected phone · disconnected", @"선택한 휴대폰 · 연결 끊김")];
        self.deviceBox.lastItem.representedObject = self.identity;
        [self.deviceBox selectItem:self.deviceBox.lastItem];
    }
}
- (NSDictionary *)currentDevice { for (NSDictionary *device in self.devices) if ([device[@"identity"] isEqual:self.identity]) return device; return nil; }
- (void)showError:(NSString *)error {
    if (self.closing) return;
    self.message.stringValue = error ?: @"";
    NSAlert *alert = [[NSAlert alloc] init]; alert.messageText = L(@"DX Manager", @"DX Manager"); alert.informativeText = error ?: @"";
    [alert beginSheetModalForWindow:self.window completionHandler:nil];
}
- (void)request:(NSString *)command fields:(NSDictionary *)fields done:(DXReply)done {
    self.busy = YES; self.lastInteraction = NSDate.date;
    self.message.stringValue = L(@"Working…", @"처리 중…"); [self.progress startAnimation:nil]; [self updateEnabled];
    NSMutableDictionary *arguments = [@{@"device": self.identity ?: @"", @"mode": @(self.mode)} mutableCopy];
    [arguments addEntriesFromDictionary:fields ?: @{}];
    [self.bridge send:command fields:arguments reply:^(id data, NSString *error) {
        self.busy = NO; [self.progress stopAnimation:nil];
        if (error) [self showError:error]; else self.message.stringValue = [data isKindOfClass:NSDictionary.class] ? S(data[@"message"]) : @"";
        if (done) done(data, error); [self updateEnabled];
    }];
}
- (void)loadSettings:(void (^)(void))done {
    [self request:@"settings" fields:nil done:^(id data, NSString *error) {
        if (!error) {
            self.settings = data; DXLanguage = [data[@"general"][@"language"] integerValue];
            NSInteger theme = [data[@"general"][@"theme"] integerValue];
            NSApp.appearance = theme == 0 ? nil : [NSAppearance appearanceNamed:theme == 2 ? NSAppearanceNameDarkAqua : NSAppearanceNameAqua];
            [self.desktop configure:data[@"desktop"] language:DXLanguage];
            [self buildMenu]; [self renderPage]; self.dirty = NO;
        }
        if (done) done();
    }];
}
- (void)poll {
    if (self.busy || self.polling || self.closing || !self.bridge.task.running) return;
    self.polling = YES;
    [self.bridge send:@"state" fields:@{} reply:^(id data, NSString *error) {
        self.polling = NO; if (error || self.closing) return;
        [self.desktop setSessions:data[@"sessions"]];
        if(self.permissionLabel) self.permissionLabel.stringValue=self.desktop.permissionStatus;
        NSArray *devices = [data[@"devices"] arrayByAddingObjectsFromArray:data[@"detached"]];
        // Keep an open device menu stable while unchanged monitor snapshots arrive.
        if (![self.devices isEqualToArray:devices]) { self.devices = devices; [self rebuildDevices]; }
        self.transfer = data[@"transfers"][self.identity]; self.receive = data[@"receives"][self.identity];
        [self updateTransfer];
        NSDictionary *device = self.currentDevice;
        BOOL connected = B(device[@"connected"]); NSArray *running = device[@"running"];
        BOOL active = (NSInteger)running.count > self.mode && B(running[self.mode]);
        self.status.stringValue = active ? L(@"Running", @"실행 중") : connected ? L(@"Phone connected", @"휴대폰 연결됨") : L(@"Waiting for a device", @"휴대폰 연결 대기");
        self.detail.stringValue = connected ? [NSString stringWithFormat:L(@"%@ · %@\nSelect options below, then start.", @"%@ · %@\n아래 설정을 확인하고 시작하세요."), S(device[@"name"]), S(device[@"transport"])] : L(@"Select a connected device above. Enable USB debugging and approve the phone's RSA prompt.", @"위에서 연결된 기기를 선택하세요. USB 디버깅을 켜고 휴대폰의 연결 승인창을 확인하세요.");
        [self updateEnabled];
        // Auto-start applies only to the explicitly selected physical device, once
        // per GUI lifetime; manual Stop does not trigger an immediate restart.
        NSDictionary *general = self.settings[@"general"];
        if (connected && B(device[@"stable"]) && B(general[@"autoStart"]) && ![self.autoStarted containsObject:self.identity]) {
            NSString *target = self.identity; [self.autoStarted addObject:target];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, [general[@"startDelay"] longLongValue] * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                if (!self.busy && !self.closing && [target isEqual:self.identity] && B(self.currentDevice[@"connected"]))
                    [self request:@"start" fields:@{@"mode": @0} done:nil];
            });
        }
        if (active && B(general[@"autoHide"]) && !self.dirty && !self.window.attachedSheet &&
            -[self.lastInteraction timeIntervalSinceNow] > [general[@"hideDelay"] integerValue]) [self.window miniaturize:nil];
    }];
}
- (void)updateEnabled {
    BOOL usable = !self.busy && !self.closing && self.bridge.task.running;
    for (NSControl *action in self.actions) action.enabled = usable;
    for (NSControl *field in self.fields.allValues) field.enabled = usable;
    self.deviceBox.enabled = usable;
    NSDictionary *device = self.currentDevice; NSArray *running = device[@"running"];
    BOOL active = (NSInteger)running.count > self.mode && B(running[self.mode]);
    self.startButton.enabled = usable && B(device[@"connected"]) && B(device[@"stable"]) && !active;
    self.stopButton.enabled = usable && active;
}
- (void)renderPage {
    for (NSView *view in self.pane.subviews.copy) [view removeFromSuperview];
    for (NSView *view in self.footer.subviews.copy) [view removeFromSuperview];
    for (NSButton *button in self.navigationButtons) button.state = button.tag == (self.page == 0 ? self.mode : self.page) ? NSControlStateValueOn : NSControlStateValueOff;
    [self.actions removeObjectsAtIndexes:[self.actions indexesOfObjectsPassingTest:^BOOL(NSControl *control, NSUInteger idx, BOOL *stop) { (void)idx; (void)stop; return ![control isDescendantOf:self.root]; }]];
    self.fields = [NSMutableDictionary dictionary]; self.startButton = nil; self.stopButton = nil; self.transferLabel = nil; self.permissionLabel = nil;
    self.pane.frame = NSMakeRect(0, 0, 690, 540);
    if (self.page == 0) [self renderRun];
    else if (self.page == 10) [self renderGeneral];
    else if (self.page == 11) [self renderConnection];
    else if (self.page == 12) [self renderPaths];
    else if (self.page == 13) [self renderKeyboard];
    else if (self.page == 14) [self renderDiagnostics];
    else [self renderAbout];
    [self updateEnabled];
}
- (void)renderRun {
    DXFlippedView *display = [self card:self.mode == 0 ? L(@"DeX display settings", @"DeX 화면 설정") : [NSString stringWithFormat:L(@"Single window %ld display settings", @"단일창 %ld 화면 설정"), (long)self.mode] y:0 height:190];
    NSPopUpButton *resolution = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(20, 48, 308, 29) pullsDown:NO];
    [resolution addItemsWithTitles:@[L(@"Resolution preset…", @"해상도 프리셋…"), @"1280 × 720", @"1600 × 900", @"1920 × 1080", @"2560 × 1440", @"3840 × 2160", @"1080 × 1920"]]; resolution.target = self; resolution.action = @selector(resolution:); [display addSubview:resolution]; [self.actions addObject:resolution];
    [self text:@"width" title:L(@"Width", @"너비") x:20 y:83 width:145 parent:display];
    [self text:@"height" title:L(@"Height", @"높이") x:180 y:83 width:148 parent:display];
    [self text:@"dpi" title:@"DPI" x:360 y:28 width:306 parent:display];
    [self text:@"bitRate" title:L(@"Video bitrate (e.g. 8M)", @"비트레이트 (예: 8M)") x:360 y:95 width:145 parent:display];
    [self text:@"maxFps" title:L(@"Maximum FPS", @"최대 FPS") x:520 y:95 width:146 parent:display];
    DXFlippedView *options = [self card:L(@"Run options", @"실행 옵션") y:206 height:318];
    [self check:@"turnScreenOff" title:L(@"Turn phone screen off (-S)", @"폰 화면 끄기 (-S)") x:20 y:47 parent:options];
    [self check:@"useHidKeyboard" title:L(@"HID keyboard (-K)", @"HID 키보드 (-K)") x:20 y:82 parent:options];
    [self check:@"useHidMouse" title:L(@"HID mouse (-M)", @"HID 마우스 (-M)") x:20 y:117 parent:options];
    [self check:@"forceStopStartApp" title:L(@"Force stop selected app", @"선택 앱 강제 종료") x:360 y:47 parent:options];
    [self check:@"stayAwake" title:L(@"Keep awake", @"잠자기 방지") x:360 y:82 parent:options];
    if (self.mode > 0) [self check:@"flexDisplay" title:L(@"Resize display with window", @"창 크기에 맞춰 화면 조절") x:360 y:117 parent:options];
    [self label:L(@"Start app", @"시작 앱") frame:NSMakeRect(20, 158, 470, 20) font:12 parent:options];
    NSComboBox *apps = [[NSComboBox alloc] initWithFrame:NSMakeRect(20, 181, 463, 28)]; apps.delegate = (id)self;
    apps.target = self; apps.action = @selector(appChanged:); apps.accessibilityLabel = L(@"Start app package", @"시작 앱 패키지");
    for (NSDictionary *app in self.apps) [apps addItemWithObjectValue:[NSString stringWithFormat:@"%@ (%@)", S(app[@"name"]), S(app[@"packageName"])]];
    [options addSubview:apps]; self.fields[@"startAppPackage"] = apps;
    [self button:L(@"Load apps", @"앱 목록 불러오기") action:@selector(loadApps:) frame:NSMakeRect(493, 180, 176, 30) parent:options];
    [self text:@"additionalArguments" title:L(@"Advanced options (additional scrcpy arguments)", @"고급 옵션 (추가 scrcpy 인자)") x:20 y:226 width:646 parent:options];
    NSDictionary *run = self.settings[@"run"];
    for (NSString *key in @[@"width", @"height", @"dpi", @"bitRate", @"maxFps", @"additionalArguments", @"startAppPackage"]) [self setText:key value:run[key]];
    for (NSString *key in @[@"turnScreenOff", @"stayAwake", @"useHidKeyboard", @"useHidMouse", @"forceStopStartApp", @"flexDisplay"]) if (self.fields[key]) [self setCheck:key value:run[key]];
    if (self.mode > 0) {
        self.pane.frame = NSMakeRect(0, 0, 690, 576);
        NSArray *titles = @[L(@"Save app profile", @"앱 설정 저장"), L(@"Load profile", @"앱 설정 불러오기"), L(@"Delete profile", @"앱 설정 삭제")];
        for (NSInteger i = 0; i < 3; i++) { NSButton *b = [self button:titles[i] action:@selector(profile:) frame:NSMakeRect(i * 178, 534, 174, 30) parent:self.pane]; b.tag = i; }
    }
    [self button:L(@"Save settings", @"설정 저장") action:@selector(save:) frame:NSMakeRect(350, 0, 156, 32) parent:self.footer];
    self.stopButton = [self button:L(@"Stop", @"중지") action:@selector(stop:) frame:NSMakeRect(510, 0, 78, 32) parent:self.footer];
    self.startButton = [self button:self.mode == 0 ? L(@"Start DeX", @"DeX 시작") : L(@"Start", @"시작") action:@selector(start:) frame:NSMakeRect(592, 0, 96, 32) parent:self.footer]; self.startButton.bezelColor = NSColor.systemPurpleColor;
}
- (void)renderGeneral {
    NSDictionary *general = self.settings[@"general"];
    DXFlippedView *appearance = [self card:L(@"Appearance & language", @"화면 및 언어") y:0 height:144];
    NSArray *keys = @[@"language", @"theme"];
    NSArray *titles = @[L(@"Display language", @"표시 언어"), L(@"App theme", @"앱 테마")];
    NSArray *options = @[@[L(@"System", @"시스템 설정"), @"한국어", @"English"], @[L(@"System", @"시스템 설정"), L(@"Light", @"밝게"), L(@"Dark", @"어둡게")]];
    for (NSInteger i = 0; i < 2; i++) {
        [self label:titles[i] frame:NSMakeRect(20, 50 + i * 43, 260, 22) font:13 parent:appearance];
        NSPopUpButton *box = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(290, 46 + i * 43, 375, 30) pullsDown:NO];
        [box addItemsWithTitles:options[i]]; [box selectItemAtIndex:[general[keys[i]] integerValue]]; box.target = self; box.action = @selector(edited:); self.fields[keys[i]] = box; [appearance addSubview:box];
    }
    DXFlippedView *startup = [self card:L(@"Startup & automatic actions", @"시작 및 자동 실행") y:160 height:288];
    [self check:@"login" title:L(@"Open at Mac login", @"Mac 로그인 시 자동 실행") x:20 y:46 parent:startup];
    [self check:@"startMinimized" title:L(@"Start minimized", @"최소화하여 시작") x:360 y:46 parent:startup];
    [self check:@"autoStart" title:L(@"Auto-start DeX on selected device", @"선택 기기 연결 시 DeX 자동 시작") x:20 y:91 parent:startup];
    [self text:@"startDelay" title:L(@"Start delay (seconds)", @"시작 대기 (초)") x:360 y:79 width:305 parent:startup];
    [self check:@"autoHide" title:L(@"Minimize after starting", @"실행 후 자동 최소화") x:20 y:155 parent:startup];
    [self text:@"hideDelay" title:L(@"Minimize delay (seconds)", @"최소화 대기 (초)") x:360 y:143 width:305 parent:startup];
    [self check:@"restoreAwake" title:L(@"Restore stay-awake on stop", @"종료 시 잠자기 방지 복원") x:20 y:215 parent:startup];
    [self label:L(@"Display cleanup always runs when stopping or quitting.", @"중지·종료 시 가상 디스플레이 정리는 항상 수행합니다.") frame:NSMakeRect(20, 247, 645, 26) font:12 parent:startup];
    for (NSString *key in @[@"login", @"startMinimized", @"autoStart", @"autoHide", @"restoreAwake"]) [self setCheck:key value:general[key]];
    [self setText:@"startDelay" value:general[@"startDelay"]]; [self setText:@"hideDelay" value:general[@"hideDelay"]];
    [self label:L(@"Auto-start uses the device you select, once per app launch. Open the app again from the Dock after minimizing.", @"자동 시작은 명시적으로 선택한 기기에 앱 실행당 한 번 적용합니다. 최소화한 창은 Dock에서 다시 열 수 있습니다.") frame:NSMakeRect(20, 465, 645, 56) font:12 parent:self.pane];
    [self button:L(@"Save", @"저장") action:@selector(save:) frame:NSMakeRect(548, 0, 140, 34) parent:self.footer];
}
- (void)renderConnection {
    DXFlippedView *card = [self card:L(@"Wireless ADB", @"무선 ADB 연결") y:0 height:343];
    [self text:@"host" title:L(@"Phone IP address", @"휴대폰 IP 주소") x:20 y:48 width:405 parent:card];
    [self text:@"port" title:L(@"Connection port", @"연결 포트") x:449 y:48 width:214 parent:card];
    NSDictionary *wireless = [self.settings[@"wireless"] isKindOfClass:NSDictionary.class] ? self.settings[@"wireless"] : @{};
    [self setText:@"host" value:wireless[@"wirelessHost"]]; [self setText:@"port" value:wireless[@"wirelessPort"] ?: @5555];
    [self check:@"reconnect" title:L(@"Automatically reconnect", @"자동 재연결") x:20 y:120 parent:card]; [self setCheck:@"reconnect" value:wireless[@"autoReconnect"] ?: @YES];
    NSArray *titles = @[L(@"Prepare via USB", @"USB에서 무선 준비"), L(@"Connect", @"연결"), L(@"Disconnect selected", @"선택 기기 연결 해제")];
    for (NSInteger i = 0; i < 3; i++) { NSButton *b = [self button:titles[i] action:@selector(wireless:) frame:NSMakeRect(20 + i * 218, 165, 207, 34) parent:card]; b.tag = i; }
    [self label:L(@"For Android wireless debugging, enter the pairing port and code below. The pairing port and connection port can differ.", @"Android 무선 디버깅에서는 아래에 페어링 포트와 코드를 입력하세요. 연결 포트와 페어링 포트는 다를 수 있습니다.") frame:NSMakeRect(20, 224, 645, 60) font:13 parent:card];
    DXFlippedView *pair = [self card:L(@"Pair device", @"기기 페어링") y:359 height:180];
    [self text:@"pairPort" title:L(@"Pairing port", @"페어링 포트") x:20 y:47 width:200 parent:pair];
    [self text:@"code" title:L(@"Pairing code", @"페어링 코드") x:244 y:47 width:200 parent:pair];
    NSButton *b = [self button:L(@"Pair", @"페어링") action:@selector(wireless:) frame:NSMakeRect(467, 67, 198, 32) parent:pair]; b.tag = 3;
    [self label:L(@"USB: connect the cable and authorize debugging on the phone. No connection button is needed.", @"USB는 케이블 연결 후 휴대폰에서 디버깅을 승인하면 됩니다. 별도 연결 버튼은 필요하지 않습니다.") frame:NSMakeRect(20, 124, 645, 46) font:12 parent:pair];
}
- (void)renderPaths {
    NSDictionary *paths = self.settings[@"paths"], *general = self.settings[@"general"];
    DXFlippedView *tools = [self card:L(@"Bundled tools & storage", @"번들 도구 및 저장 위치") y:0 height:218];
    NSString *text = [NSString stringWithFormat:@"ADB: %@\nscrcpy: %@\n%@: %@", S(paths[@"adb"]), S(paths[@"scrcpy"]), L(@"Settings", @"설정"), S(paths[@"config"])];
    NSTextField *label = [self label:text frame:NSMakeRect(20, 48, 645, 156) font:12 parent:tools]; label.selectable = YES;
    DXFlippedView *transfer = [self card:L(@"File transfers", @"파일 전송") y:234 height:288];
    [self text:@"send" title:L(@"Phone destination folder", @"휴대폰 전송 대상 폴더") x:20 y:47 width:645 parent:transfer];
    [self text:@"receive" title:L(@"Mac receive folder", @"Mac 수신 폴더") x:20 y:113 width:645 parent:transfer];
    [self setText:@"send" value:paths[@"send"]]; [self setText:@"receive" value:paths[@"receive"]];
    [self check:@"managedTransfer" title:L(@"Managed drag-and-drop transfers", @"드래그 전송 관리") x:20 y:181 parent:transfer];
    [self check:@"phoneTransfer" title:L(@"Receive from DX Companion", @"DX Companion에서 파일 받기") x:360 y:181 parent:transfer];
    [self setCheck:@"managedTransfer" value:general[@"managedTransfer"]]; [self setCheck:@"phoneTransfer" value:general[@"phoneTransfer"]];
    [self button:L(@"Send file / folder…", @"파일 / 폴더 보내기…") action:@selector(sendFile:) frame:NSMakeRect(20, 230, 255, 34) parent:transfer];
    [self button:L(@"Open receive folder", @"수신 폴더 열기") action:@selector(openReceive:) frame:NSMakeRect(365, 230, 298, 34) parent:transfer];
    DXFlippedView *progress = [self card:L(@"Transfer activity", @"전송 상태") y:538 height:194];
    self.transferLabel = [self label:@"" frame:NSMakeRect(20, 48, 645, 94) font:12 parent:progress];
    [self button:L(@"Cancel outgoing transfer", @"보내는 전송 취소") action:@selector(cancelTransfer:) frame:NSMakeRect(20, 148, 280, 32) parent:progress];
    [self updateTransfer];
    self.pane.frame = NSMakeRect(0, 0, 690, 744);
    [self button:L(@"Save", @"저장") action:@selector(save:) frame:NSMakeRect(548, 0, 140, 34) parent:self.footer];
}
- (void)updateTransfer {
    if (!self.transferLabel) return;
    NSString *outgoing = self.transfer ? [NSString stringWithFormat:@"%@ · %@ · %@ bytes · %@ completed / %@ queued", S(self.transfer[@"stage"]), S(self.transfer[@"item"]), self.transfer[@"bytes"], self.transfer[@"completed"], self.transfer[@"queued"]] : L(@"No managed outgoing transfer", @"관리 중인 보내기 없음");
    NSString *incoming = self.receive ? [NSString stringWithFormat:@"%@ · %@ · %@ bytes", S(self.receive[@"stage"]), S(self.receive[@"item"]), self.receive[@"bytes"]] : L(@"No incoming transfer", @"수신 중인 전송 없음");
    self.transferLabel.stringValue = [NSString stringWithFormat:@"%@\n%@", outgoing, incoming];
}
- (void)cancelTransfer:(id)sender { (void)sender; if (S(self.transfer[@"requestId"]).length) [self request:@"cancel-transfer" fields:@{@"requestId": self.transfer[@"requestId"]} done:nil]; }
- (void)renderKeyboard {
    NSDictionary *d=self.settings[@"desktop"];
    DXFlippedView *keys=[self card:L(@"Global keys · focused DeX / app window only", @"전역 키 · 현재 DeX / 단일창에만 적용") y:0 height:342];
    [self check:@"enabled" title:L(@"Enable keys and capture shortcuts", @"키 변환과 캡처 단축키 사용") x:20 y:48 parent:keys];
    [self check:@"hangul" title:L(@"Right Option → Shift+Space", @"오른쪽 Option → 한/영 전환") x:20 y:88 parent:keys];
    [self check:@"enter" title:L(@"F14 toggles Enter / Shift+Enter", @"F14로 Enter / Shift+Enter 전환") x:360 y:88 parent:keys];
    [self check:@"ignoreShiftSpace" title:L(@"Ignore physical Shift+Space", @"직접 Shift+Space 입력 무시") x:20 y:128 parent:keys];
    [self check:@"rightCommand" title:L(@"Right Command compatibility", @"오른쪽 Command 호환 입력") x:360 y:128 parent:keys];
    [self label:L(@"Hangul input", @"한/영 입력 방식") frame:NSMakeRect(20,178,300,20) font:12 parent:keys];
    [self label:L(@"Enter input", @"Enter 입력 방식") frame:NSMakeRect(360,178,300,20) font:12 parent:keys];
    for(NSString *key in @[@"hangulMode",@"enterMode"]) {
        NSPopUpButton *box=[[NSPopUpButton alloc] initWithFrame:NSMakeRect([key isEqual:@"hangulMode"]?20:360,202,305,30) pullsDown:NO];
        [box addItemsWithTitles:@[L(@"scrcpy native input", @"scrcpy 네이티브 입력"), L(@"ADB · selected display", @"ADB · 해당 디스플레이")]];
        [box selectItemAtIndex:[d[key] integerValue]==2?1:0];box.target=self;box.action=@selector(edited:);self.fields[key]=box;[keys addSubview:box];
    }
    [self label:L(@"F14 is Scroll Lock on many external keyboards. Enter starts in normal mode. Right Shift is paired with left Shift for SDL compatibility. Right Command uses balanced left Command events on Mac. Other applications keep their normal keys.", @"외장 키보드의 Scroll Lock은 Mac에서 F14로 동작합니다. Enter는 일반 모드로 시작합니다. 오른쪽 Shift·Command는 왼쪽 키 입력으로 짝을 맞춰 전달합니다. 다른 앱의 키는 바꾸지 않습니다.") frame:NSMakeRect(20,255,645,76) font:12 parent:keys];
    DXFlippedView *capture=[self card:L(@"Capture and stop shortcuts", @"캡처와 중지 단축키") y:358 height:194];
    [self text:@"captureHotkey" title:L(@"Capture", @"캡처") x:20 y:47 width:200 parent:capture];
    [self text:@"exitHotkey" title:L(@"Stop focused session", @"현재 창 중지") x:244 y:47 width:200 parent:capture];
    [self text:@"captureWait" title:L(@"Wait (seconds)", @"선택 대기 (초)") x:468 y:47 width:195 parent:capture];
    [self label:L(@"Press capture once, then again for the whole window, or drag a region. Esc / timeout cancels. F1–F20 plus Ctrl, Option, Shift, Cmd are supported. On a Mac keyboard, use Fn if the top row controls media.", @"캡처 키를 한 번 누른 뒤 다시 누르면 전체 창, 드래그하면 영역을 저장합니다. Esc·시간 초과는 취소합니다. F1~F20과 Ctrl·Option·Shift·Cmd를 지원합니다. 기능 키가 미디어 조작이면 Fn도 누르세요.") frame:NSMakeRect(20,113,645,72) font:12 parent:capture];
    DXFlippedView *mini=[self card:L(@"Mini control bar", @"미니 컨트롤바") y:568 height:105];
    [self check:@"miniBar" title:L(@"Attach to focused scrcpy window", @"현재 scrcpy 창 옆에 표시") x:20 y:48 parent:mini];
    NSPopUpButton *side=[[NSPopUpButton alloc] initWithFrame:NSMakeRect(360,46,305,30) pullsDown:NO];[side addItemsWithTitles:@[L(@"Right",@"오른쪽"),L(@"Left",@"왼쪽")]];[side selectItemAtIndex:[d[@"miniSide"] integerValue]];side.target=self;side.action=@selector(edited:);self.fields[@"miniSide"]=side;[mini addSubview:side];
    DXFlippedView *storage=[self card:L(@"Capture storage", @"캡처 저장 위치") y:689 height:230];
    [self text:@"screenshotFolder" title:L(@"Mac screenshot folder", @"Mac 캡처 폴더") x:20 y:47 width:645 parent:storage];
    [self text:@"phoneScreenshotFolder" title:L(@"Phone screenshot folder", @"휴대폰 캡처 폴더") x:20 y:113 width:645 parent:storage];
    [self check:@"pushCapture" title:L(@"Also copy capture to its phone", @"캡처한 휴대폰에도 파일 전송") x:20 y:182 parent:storage];
    DXFlippedView *permission=[self card:L(@"macOS permissions", @"macOS 권한") y:935 height:168];
    self.permissionLabel=[self label:self.desktop.permissionStatus frame:NSMakeRect(20,47,645,24) font:12 parent:permission];
    [self button:L(@"Allow Accessibility…", @"손쉬운 사용 허용…") action:@selector(allowAccessibility:) frame:NSMakeRect(20,83,307,32) parent:permission];
    [self button:L(@"Allow Screen Recording…", @"화면 기록 허용…") action:@selector(allowCapture:) frame:NSMakeRect(358,83,307,32) parent:permission];
    [self label:L(@"Grant only the permissions you use. Reopen this app if macOS asks after approval.", @"사용할 기능의 권한만 허용하세요. macOS가 요청하면 승인 후 앱을 다시 여세요.") frame:NSMakeRect(20,128,645,30) font:12 parent:permission];
    for(NSString *key in @[@"enabled",@"hangul",@"enter",@"ignoreShiftSpace",@"rightCommand",@"miniBar",@"pushCapture"]) [self setCheck:key value:d[key]];
    for(NSString *key in @[@"captureHotkey",@"exitHotkey",@"captureWait",@"screenshotFolder",@"phoneScreenshotFolder"]) [self setText:key value:d[key]];
    self.pane.frame=NSMakeRect(0,0,690,1120);
    [self button:L(@"Save",@"저장") action:@selector(save:) frame:NSMakeRect(548,0,140,34) parent:self.footer];
}
- (void)allowAccessibility:(id)sender { (void)sender; [self.desktop requestAccessibility]; }
- (void)allowCapture:(id)sender { (void)sender; [self.desktop requestScreenCapture]; }
- (void)renderDiagnostics {
    DXFlippedView *card = [self card:L(@"Diagnostics", @"진단") y:0 height:134];
    [self button:L(@"Run environment checks", @"환경 점검 실행") action:@selector(diagnostics:) frame:NSMakeRect(20, 53, 310, 36) parent:card];
    NSButton *log = [self button:L(@"View session log", @"현재 세션 로그 보기") action:@selector(diagnostics:) frame:NSMakeRect(359, 53, 308, 36) parent:card]; log.tag = 1;
    DXFlippedView *companion = [self card:@"DX Companion" y:150 height:226];
    [self label:L(@"Actions apply only to the selected device. Installation requires a verified bundled APK. The GUI does not add an APK to the release.", @"선택 기기에만 적용합니다. 설치에는 검증된 번들 APK가 필요합니다. GUI가 배포본에 APK를 추가하지는 않습니다.") frame:NSMakeRect(20, 48, 644, 60) font:13 parent:companion];
    NSArray *titles = @[L(@"Check status", @"상태 확인"), L(@"Install / update", @"설치 / 업데이트"), L(@"Grant permission", @"권한 부여"), L(@"Uninstall", @"삭제")];
    for (NSInteger i = 0; i < 4; i++) { NSButton *b = [self button:titles[i] action:@selector(companion:) frame:NSMakeRect(20 + (i % 2) * 340, 126 + (i / 2) * 45, 306, 34) parent:companion]; b.tag = i; }
    [self label:L(@"The app waits for its sessions to stop and restore display / power settings when quitting. Keep the phone connected until the app closes.", @"앱 종료 시 실행한 세션을 중지하고 디스플레이·화면 전원 설정 복원을 기다립니다. 앱이 닫힐 때까지 휴대폰 연결을 유지하세요.") frame:NSMakeRect(20, 402, 644, 90) font:13 parent:self.pane];
}
- (void)renderAbout {
    DXFlippedView *card = [self card:L(@"DX Manager for macOS", @"Mac용 DX Manager") y:0 height:435];
    [self label:L(@"Community macOS edition based on maze-mei/DX-Manager.\n\nThe native Mac window uses the same C# device and DeX services as the portable edition. Settings remain outside the signed app bundle.\n\nVersion 2.1.0 provides a native Mac GUI. Focused-window key conversion, capture and a mini control bar use macOS permissions. Device and Intel hardware validation are tracked separately.\n\nAd-hoc signed; not Apple notarized. macOS may require approval in Privacy & Security.", @"maze-mei/DX-Manager 기반의 커뮤니티 Mac 버전입니다.\n\nMac 창은 기존 포터블 버전의 C# 기기·DeX 서비스를 사용합니다. 설정은 서명된 앱 밖에 보관합니다.\n\n2.1.0은 Mac 네이티브 GUI를 제공합니다. 키 변환·캡처·미니 컨트롤바는 macOS 권한을 사용합니다. 기기·Intel 실기 확인은 별도입니다.\n\n무결성 확인용 ad-hoc 서명이며 Apple 공증은 없습니다. 개인정보 보호 및 보안에서 실행 승인이 필요할 수 있습니다.") frame:NSMakeRect(20, 50, 645, 320) font:14 parent:card];
    [self button:L(@"Project releases", @"프로젝트 릴리스") action:@selector(openProject:) frame:NSMakeRect(20, 382, 290, 32) parent:card];
}
- (void)resolution:(NSPopUpButton *)sender {
    NSArray *parts = [sender.titleOfSelectedItem componentsSeparatedByString:@" × "];
    if (parts.count == 2) { [self setText:@"width" value:parts[0]]; [self setText:@"height" value:parts[1]]; [self edited:sender]; }
}
- (NSDictionary *)runValues {
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    for (NSString *key in @[@"width", @"height", @"dpi", @"maxFps"]) {
        NSString *text = [self textValue:key]; NSScanner *scan = [NSScanner scannerWithString:text]; NSInteger number;
        if (![scan scanInteger:&number] || !scan.isAtEnd) { [self showError:L(@"Enter a whole number for resolution, DPI and FPS.", @"해상도·DPI·FPS에는 정수를 입력하세요.")]; return nil; }
        values[key] = @(number);
    }
    for (NSString *key in @[@"turnScreenOff", @"stayAwake", @"useHidKeyboard", @"useHidMouse", @"forceStopStartApp", @"flexDisplay"]) values[key] = @([self checkValue:key]);
    for (NSString *key in @[@"bitRate", @"startAppPackage", @"additionalArguments"]) values[key] = [self textValue:key];
    values[@"startAppName"] = values[@"startAppPackage"];
    NSComboBox *box = (NSComboBox *)self.fields[@"startAppPackage"];
    NSInteger index = box.indexOfSelectedItem;
    if (index >= 0 && index < (NSInteger)self.apps.count && [box.stringValue isEqual:[box itemObjectValueAtIndex:index]]) {
        values[@"startAppPackage"] = self.apps[index][@"packageName"];
        values[@"startAppName"] = self.apps[index][@"name"];
    }
    return values;
}
- (void)saveThen:(void (^)(void))done {
    if (self.page == 0) {
        NSDictionary *values = [self runValues]; if (!values) return;
        [self request:@"save" fields:@{@"run": values} done:^(id data, NSString *error) {
            (void)data; if (!error) { self.dirty = NO; if (done) done(); }
        }];
    } else if (self.page == 13) {
        NSMutableDictionary *desktop=[NSMutableDictionary dictionary];
        for(NSString *key in @[@"enabled",@"hangul",@"enter",@"ignoreShiftSpace",@"rightCommand",@"miniBar",@"pushCapture"]) desktop[key]=@([self checkValue:key]);
        for(NSString *key in @[@"captureHotkey",@"exitHotkey",@"screenshotFolder",@"phoneScreenshotFolder"]) desktop[key]=[self textValue:key];
        NSScanner *scan=[NSScanner scannerWithString:[self textValue:@"captureWait"]];NSInteger wait;
        if(![scan scanInteger:&wait]||!scan.isAtEnd){[self showError:L(@"Enter a whole number for capture wait.",@"캡처 대기 시간에 정수를 입력하세요.")];return;}
        desktop[@"captureWait"]=@(wait);desktop[@"miniSide"]=@(((NSPopUpButton *)self.fields[@"miniSide"]).indexOfSelectedItem);
        for(NSString *key in @[@"hangulMode",@"enterMode"])desktop[key]=@(((NSPopUpButton *)self.fields[key]).indexOfSelectedItem==1?2:1);
        [self request:@"desktop" fields:@{@"desktop":desktop} done:^(id data,NSString *error){(void)data;if(!error){self.dirty=NO;if(done)done();}}];
    } else if (self.page == 10 || self.page == 12) {
        NSMutableDictionary *values = [self.settings[@"general"] mutableCopy];
        values[@"send"] = S(self.settings[@"paths"][@"send"]); values[@"receive"] = S(self.settings[@"paths"][@"receive"]);
        if (self.page == 10) {
            for (NSString *key in @[@"language", @"theme"]) values[key] = @(((NSPopUpButton *)self.fields[key]).indexOfSelectedItem);
            for (NSString *key in @[@"login", @"startMinimized", @"autoStart", @"autoHide", @"restoreAwake"]) values[key] = @([self checkValue:key]);
            for (NSString *key in @[@"startDelay", @"hideDelay"]) {
                NSScanner *scan = [NSScanner scannerWithString:[self textValue:key]]; NSInteger number;
                if (![scan scanInteger:&number] || !scan.isAtEnd) { [self showError:L(@"Enter a whole number for delays.", @"대기 시간에는 정수를 입력하세요.")]; return; }
                values[key] = @(number);
            }
        } else {
            values[@"send"] = [self textValue:@"send"]; values[@"receive"] = [self textValue:@"receive"];
            values[@"managedTransfer"] = @([self checkValue:@"managedTransfer"]); values[@"phoneTransfer"] = @([self checkValue:@"phoneTransfer"]);
        }
        [self request:@"general" fields:values done:^(id data, NSString *error) {
            (void)data; if (!error) { self.dirty = NO; if (done) done(); }
        }];
    } else { self.dirty = NO; if (done) done(); }
}
- (void)save:(id)sender { (void)sender; [self saveThen:^{ [self loadSettings:^{ [self buildShell]; }]; }]; }
- (void)navigate:(NSButton *)sender {
    NSInteger target = sender.tag;
    void (^change)(void) = ^{ self.page = target < 4 ? 0 : target; if (target < 4) self.mode = target; [self loadSettings:nil]; };
    if (self.dirty) [self saveThen:change]; else change();
}
- (void)showSettings:(id)sender { (void)sender; if (self.busy) return; NSButton *button = [[NSButton alloc] init]; button.tag = 10; [self navigate:button]; }
- (void)selectDevice:(id)sender {
    (void)sender; NSString *target = S(self.deviceBox.selectedItem.representedObject);
    // Requests preserve the previous identity while saving, then switch atomically.
    void (^change)(void) = ^{ self.identity = target; self.apps = @[]; [self loadSettings:^{ [self poll]; }]; };
    if (self.dirty) [self saveThen:change]; else change();
}
- (void)start:(id)sender { (void)sender; [self saveThen:^{ [self request:@"start" fields:nil done:^(id data, NSString *error) { (void)data; (void)error; [self.autoStarted addObject:self.identity]; [self poll]; }]; }]; }
- (void)stop:(id)sender { (void)sender; [self request:@"stop" fields:nil done:^(id data, NSString *error) { (void)data; (void)error; [self poll]; }]; }
- (void)loadApps:(id)sender {
    (void)sender;
    [self saveThen:^{ [self request:@"apps" fields:nil done:^(id data, NSString *error) { if (!error) { self.apps = data; [self loadSettings:nil]; } }]; }];
}
- (void)appChanged:(id)sender {
    [self edited:sender];
    if (self.mode == 0 || self.busy) return;
    [self saveThen:^{ [self request:@"profile-auto" fields:nil done:^(id data, NSString *error) { (void)data; if (!error) [self loadSettings:nil]; }]; }];
}
- (void)comboBoxSelectionDidChange:(NSNotification *)notification { [self appChanged:notification.object]; }
- (void)profile:(NSButton *)sender {
    NSString *command = @[@"profile-save", @"profile-load", @"profile-delete"][sender.tag];
    [self saveThen:^{ [self request:command fields:nil done:^(id data, NSString *error) { (void)data; if (!error) [self loadSettings:nil]; }]; }];
}
- (void)wireless:(NSButton *)sender {
    NSArray *commands = @[@"wireless-prepare", @"wireless-connect", @"wireless-disconnect", @"wireless-pair"];
    NSInteger port = [[self textValue:sender.tag == 3 ? @"pairPort" : @"port"] integerValue];
    if (sender.tag != 2 && (port < 1 || port > 65535)) { [self showError:L(@"Port must be between 1 and 65535.", @"포트 범위는 1~65535입니다.")]; return; }
    [self request:commands[sender.tag] fields:@{@"host": [self textValue:@"host"], @"port": @(port), @"code": [self textValue:@"code"], @"reconnect": @([self checkValue:@"reconnect"])} done:^(id data, NSString *error) { (void)data; if (!error) { self.dirty = NO; [self setText:@"code" value:@""]; [self poll]; } }];
}
- (void)sendFile:(id)sender {
    (void)sender;
    NSOpenPanel *panel = NSOpenPanel.openPanel; panel.canChooseFiles = YES; panel.canChooseDirectories = YES;
    panel.message = L(@"Direct ADB send: an existing file with the same name can be replaced. Use drag-and-drop into DeX for managed collision handling.", @"ADB 직접 전송은 같은 이름의 기존 파일을 바꿀 수 있습니다. 이름 충돌 처리가 필요하면 DeX 창에 파일을 드래그하세요.");
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) [self saveThen:^{ [self request:@"send" fields:@{@"path": panel.URL.path} done:nil]; }];
    }];
}
- (void)openReceive:(id)sender { (void)sender; NSString *path = [self textValue:@"receive"]; if (path.length) [NSWorkspace.sharedWorkspace openURL:[NSURL fileURLWithPath:path]]; }
- (void)showText:(NSString *)text title:(NSString *)title {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 800, 580) styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable backing:NSBackingStoreBuffered defer:NO];
    window.title = title; window.releasedWhenClosed = NO; window.delegate = self; [self.auxiliaryWindows addObject:window];
    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:window.contentView.bounds]; scroll.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable; scroll.hasVerticalScroller = YES;
    NSTextView *view = [[NSTextView alloc] initWithFrame:scroll.bounds]; view.editable = NO; view.font = [NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightRegular]; view.string = text ?: @""; view.autoresizingMask = NSViewWidthSizable; view.textContainer.widthTracksTextView = YES; scroll.documentView = view;
    [window.contentView addSubview:scroll]; [window center]; [window makeKeyAndOrderFront:nil];
}
- (void)diagnostics:(NSButton *)sender { NSString *command = sender.tag == 1 ? @"logs" : @"diagnostics"; [self request:command fields:nil done:^(id data, NSString *error) { if (!error) [self showText:S(data[@"text"]) title:sender.title]; }]; }
- (void)companion:(NSButton *)sender {
    void (^perform)(void) = ^{ [self request:@[@"companion-inspect", @"companion-install", @"companion-grant", @"companion-uninstall"][sender.tag] fields:nil done:^(id data, NSString *error) { if (!error) [self showText:S(data[@"message"]) title:@"DX Companion"]; }]; };
    if (sender.tag == 0) { perform(); return; }
    NSAlert *alert = [[NSAlert alloc] init]; alert.messageText = sender.title;
    alert.informativeText = [NSString stringWithFormat:L(@"Apply this action to %@?", @"%@ 기기에 이 작업을 적용할까요?"), S(self.currentDevice[@"name"])];
    [alert addButtonWithTitle:L(@"Continue", @"진행")]; [alert addButtonWithTitle:L(@"Cancel", @"취소")];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) { if (result == NSAlertFirstButtonReturn) perform(); }];
}
- (void)openProject:(id)sender { (void)sender; [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:@"https://github.com/asyouplz/DX-Manager-mac/releases"]]; }
- (BOOL)windowShouldClose:(NSWindow *)window {
    if (window == self.window) { [NSApp terminate:nil]; return NO; }
    return YES;
}
- (void)windowWillClose:(NSNotification *)notification { [self.auxiliaryWindows removeObject:notification.object]; }
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender { (void)sender; return YES; }
- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)visible { (void)sender; if (!visible) { [self.window deminiaturize:nil]; [self.window makeKeyAndOrderFront:nil]; } return YES; }
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    (void)sender;
    if (!self.bridge.task.running) return NSTerminateNow;
    if (self.closing) return NSTerminateLater;
    self.closing = YES; [self.desktop stop]; [self.timer invalidate]; self.message.stringValue = L(@"Stopping sessions and restoring device settings…", @"세션을 중지하고 기기 설정을 복원하고 있습니다…"); [self.progress startAnimation:nil]; [self updateEnabled];
    // Closing stdin is also a cancellation signal during a long launch/operation.
    [self.bridge send:@"quit" fields:@{} reply:nil]; [self.bridge.input closeFile];
    return NSTerminateLater;
}
@end

int DXRunApplication(NSString *executable) {
    [NSApplication sharedApplication];
    __attribute__((objc_precise_lifetime)) DXApp *delegate = [[DXApp alloc] init]; delegate.executable = executable;
    NSApp.delegate = delegate; [NSApp run]; return 0;
}
