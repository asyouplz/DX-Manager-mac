#import "DXDesktopControls.h"
#import <ApplicationServices/ApplicationServices.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>
#import <Carbon/Carbon.h>
#import <IOKit/hidsystem/IOLLEvent.h>

static const int64_t DXInjected = 0x44584d475549;
static BOOL Flag(NSDictionary *d, NSString *key) { return [d[key] boolValue]; }
static NSString *Str(id v) { return [v isKindOfClass:NSString.class] ? v : @""; }
static CGEventFlags ShortcutFlags = kCGEventFlagMaskShift|kCGEventFlagMaskControl|kCGEventFlagMaskAlternate|kCGEventFlagMaskCommand;
static NSRect AppKitRect(CGRect r) { return NSMakeRect(r.origin.x, NSMaxY(NSScreen.screens.firstObject.frame)-CGRectGetMaxY(r), r.size.width, r.size.height); }
// Work in macOS logical points, including on Retina and negative-origin displays.
// Prefer retaining 1:1 size; reduce only when the whole window cannot fit.
static NSRect FitWindowFrame(NSRect frame, NSRect area) {
    if (NSIsEmptyRect(frame) || NSIsEmptyRect(area)) return frame;
    CGFloat scale=MIN(1,MIN(area.size.width/frame.size.width,area.size.height/frame.size.height));
    frame.size=NSMakeSize(floor(frame.size.width*scale),floor(frame.size.height*scale));
    frame.origin.x=MIN(MAX(frame.origin.x,NSMinX(area)),NSMaxX(area)-frame.size.width);
    frame.origin.y=MIN(MAX(frame.origin.y,NSMinY(area)),NSMaxY(area)-frame.size.height);
    return frame;
}
static BOOL ReadAXFrame(AXUIElementRef window, NSRect *frame) {
    CFTypeRef position=NULL,size=NULL;CGPoint point;CGSize dimensions;
    BOOL okay=AXUIElementCopyAttributeValue(window,kAXPositionAttribute,&position)==kAXErrorSuccess &&
        AXUIElementCopyAttributeValue(window,kAXSizeAttribute,&size)==kAXErrorSuccess &&
        CFGetTypeID(position)==AXValueGetTypeID() && CFGetTypeID(size)==AXValueGetTypeID() &&
        AXValueGetValue((AXValueRef)position,kAXValueCGPointType,&point) &&
        AXValueGetValue((AXValueRef)size,kAXValueCGSizeType,&dimensions);
    if(okay)*frame=AppKitRect(CGRectMake(point.x,point.y,dimensions.width,dimensions.height));
    if(position)CFRelease(position);if(size)CFRelease(size);return okay;
}
static BOOL Shortcut(NSString *value, CGKeyCode key, CGEventFlags flags) {
    NSString *s = [[[value stringByReplacingOccurrencesOfString:@"LeftAlt" withString:@"Option"] stringByReplacingOccurrencesOfString:@"Alt" withString:@"Option"] lowercaseString];
    NSArray *parts=[s componentsSeparatedByString:@"+"];
    NSArray *codes=@[@122,@120,@99,@118,@96,@97,@98,@100,@101,@109,@103,@111,@105,@107,@113,@106,@64,@79,@80,@90];
    NSString *last=parts.lastObject; if (![last hasPrefix:@"f"]) return NO;
    NSInteger n=[[last substringFromIndex:1] integerValue]; if(n<1||n>20||[codes[n-1] unsignedShortValue]!=key) return NO;
    CGEventFlags wanted=0;
    for(NSString *p in parts) { if([p isEqual:@"shift"]) wanted|=kCGEventFlagMaskShift; if([p isEqual:@"ctrl"]||[p isEqual:@"control"]) wanted|=kCGEventFlagMaskControl; if([p isEqual:@"option"]) wanted|=kCGEventFlagMaskAlternate; if([p isEqual:@"cmd"]||[p isEqual:@"command"]) wanted|=kCGEventFlagMaskCommand; }
    return (flags & ShortcutFlags)==wanted;
}

// SF Symbols availability differs by macOS version. NSButton's image-only
// factory asserts on nil, so a missing symbol must retain a usable text button.
static NSButton *MiniButton(NSImage *image, NSString *fallback, id target, SEL action) {
    NSButton *button = [NSButton buttonWithTitle:fallback target:target action:action];
    if (image) { button.image=image; button.imagePosition=NSImageOnly; }
    return button;
}

@interface DXMiniPanel : NSPanel
@end
@implementation DXMiniPanel
- (BOOL)canBecomeKeyWindow { return NO; }
- (BOOL)canBecomeMainWindow { return NO; }
@end
@interface DXCapturePanel : NSPanel
@end
@implementation DXCapturePanel
- (BOOL)canBecomeKeyWindow { return YES; }
@end
@interface DXSelectionView : NSView
@property NSImage *image;
@property NSString *hint;
@property NSPoint start;
@property NSRect selection;
@property(copy) void (^selected)(NSRect);
@property(copy) void (^cancelled)(void);
@property(copy) void (^full)(void);
@end
@implementation DXSelectionView
- (BOOL)isFlipped { return YES; }
- (BOOL)acceptsFirstResponder { return YES; }
- (void)drawRect:(NSRect)dirty { (void)dirty;
    [self.image drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1 respectFlipped:YES hints:nil];
    [[NSColor colorWithWhite:0 alpha:0.23] setFill]; NSRectFillUsingOperation(self.bounds,NSCompositingOperationSourceOver);
    [[NSColor whiteColor] setStroke]; NSBezierPath *p=[NSBezierPath bezierPathWithRect:self.selection];p.lineWidth=2;[p stroke];
    NSRect box=NSMakeRect(12,12,MAX(100,self.bounds.size.width-24),54);
    [[NSColor colorWithWhite:0 alpha:0.8] setFill];[[NSBezierPath bezierPathWithRoundedRect:box xRadius:8 yRadius:8] fill];
    [self.hint drawInRect:NSInsetRect(box,10,8) withAttributes:@{NSFontAttributeName:[NSFont systemFontOfSize:13],NSForegroundColorAttributeName:NSColor.whiteColor}];
}
- (void)mouseDown:(NSEvent *)event { self.start=[self convertPoint:event.locationInWindow fromView:nil];self.selection=NSZeroRect; }
- (void)mouseDragged:(NSEvent *)event { NSPoint p=[self convertPoint:event.locationInWindow fromView:nil];self.selection=NSIntersectionRect(self.bounds,NSMakeRect(MIN(p.x,self.start.x),MIN(p.y,self.start.y),fabs(p.x-self.start.x),fabs(p.y-self.start.y)));self.needsDisplay=YES; }
- (void)mouseUp:(NSEvent *)event { [self mouseDragged:event];if(self.selection.size.width>=4&&self.selection.size.height>=4&&self.selected)self.selected(self.selection); }
- (void)keyDown:(NSEvent *)event { if(event.keyCode==kVK_Escape) {if(self.cancelled)self.cancelled();} else if(event.keyCode==kVK_F8) {if(self.full)self.full();} }
@end

@interface DXDesktopControls ()
@property NSDictionary *settings;
@property(nonatomic) NSArray<NSDictionary *> *sessions;
@property NSMutableDictionary<NSNumber *,NSDictionary *> *windows;
@property NSMutableDictionary<NSNumber *,DXMiniPanel *> *bars;
@property NSMutableSet<NSNumber *> *collapsed;
@property NSMutableDictionary<NSNumber *,NSDictionary *> *held;
@property NSMutableDictionary<NSNumber *,NSNumber *> *enterModes;
@property NSTimer *timer;
@property NSTimer *captureTimer;
@property DXCapturePanel *overlay;
@property NSDictionary *captureTarget;
@property NSUInteger captureGeneration;
@property BOOL captureBusy;
@property BOOL running;
@property BOOL korean;
@property pid_t previousFocus;
@property CFMachPortRef tap;
@property CFRunLoopSourceRef tapSource;
@end
static CGEventRef DXTap(CGEventTapProxy proxy,CGEventType type,CGEventRef event,void *context);
@implementation DXDesktopControls
- (instancetype)init { if((self=[super init])) {self.sessions=@[];self.windows=[NSMutableDictionary dictionary];self.bars=[NSMutableDictionary dictionary];self.held=[NSMutableDictionary dictionary];self.enterModes=[NSMutableDictionary dictionary];self.collapsed=[NSMutableSet set];self.running=YES; self.timer=[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(refresh) userInfo:nil repeats:YES];}return self; }
- (NSString *)t:(NSString *)en ko:(NSString *)ko {return self.korean?ko:en;}
- (void)notify:(NSString *)text { if(self.message)self.message(text); }
- (NSString *)permissionStatus { return [NSString stringWithFormat:[self t:@"Accessibility: %@ · Screen Recording: %@" ko:@"손쉬운 사용: %@ · 화면 기록: %@"],AXIsProcessTrusted()?[self t:@"allowed" ko:@"허용됨"]:[self t:@"approval needed" ko:@"승인 필요"],CGPreflightScreenCaptureAccess()?[self t:@"allowed" ko:@"허용됨"]:[self t:@"approval needed" ko:@"승인 필요"]]; }
- (void)requestAccessibility { NSDictionary *o=@{(__bridge NSString *)kAXTrustedCheckOptionPrompt:@YES};AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)o);[self notify:self.permissionStatus]; }
- (void)requestScreenCapture { CGRequestScreenCaptureAccess();[self notify:self.permissionStatus]; }
- (void)configure:(NSDictionary *)settings language:(NSInteger)language {
    BOOL changed=self.settings&&![self.settings isEqual:settings];
    if(changed){[self releaseHeld];[self cancelCapture];[self.enterModes removeAllObjects];}
    self.settings=settings?:@{}; self.korean=language==1||(language==0&&[NSLocale.preferredLanguages.firstObject hasPrefix:@"ko"]);
    for(NSPanel *p in self.bars.allValues)[p close];[self.bars removeAllObjects];[self refresh];
}
- (void)setSessions:(NSArray<NSDictionary *> *)sessions { _sessions=[sessions copy]?:@[];[self refresh]; }
- (NSDictionary *)sessionForPid:(pid_t)pid {for(NSDictionary *s in self.sessions)if([s[@"pid"] intValue]==pid)return s;return nil;}
- (NSDictionary *)focusedWindow { pid_t pid=NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier;for(NSDictionary *w in self.windows.allValues)if([w[@"pid"] intValue]==pid)return w;return nil; }
- (BOOL)live:(NSDictionary *)target {
    if(!self.running||!target)return NO;
    NSDictionary *s=[self sessionForPid:[target[@"pid"] intValue]];
    if(!s||![s[@"device"] isEqual:target[@"device"]]||![s[@"mode"] isEqual:target[@"mode"]])return NO;
    NSDictionary *w=self.windows[target[@"window"]];return w&&[w[@"pid"] isEqual:target[@"pid"]];
}
- (void)refresh {
    if(!self.running)return;
    NSArray *list=CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly|kCGWindowListExcludeDesktopElements,kCGNullWindowID));
    NSMutableDictionary *found=[NSMutableDictionary dictionary]; NSMutableSet *ambiguous=[NSMutableSet set];NSMutableSet *seen=[NSMutableSet set];
    for(NSDictionary *w in list){NSNumber *pid=w[(__bridge NSString *)kCGWindowOwnerPID];NSDictionary *s=[self sessionForPid:pid.intValue];if(!s||[w[(__bridge NSString *)kCGWindowLayer] intValue]!=0)continue;
        CGRect rect; if(!CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)w[(__bridge NSString *)kCGWindowBounds],&rect)||rect.size.width<100||rect.size.height<100)continue;
        if([seen containsObject:pid])[ambiguous addObject:pid];[seen addObject:pid];
        NSMutableDictionary *target=[s mutableCopy];target[@"window"]=w[(__bridge NSString *)kCGWindowNumber];target[@"frame"]=[NSValue valueWithRect:AppKitRect(rect)];found[target[@"window"]]=target;
    }
    for(NSNumber *key in found.allKeys.copy)if([ambiguous containsObject:found[key][@"pid"]])[found removeObjectForKey:key]; self.windows=found;
    pid_t focus=NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier;
    if(focus!=self.previousFocus){[self releaseHeld];self.previousFocus=focus;}
    if(self.captureTarget&&![self live:self.captureTarget])[self cancelCapture];
    BOOL want=Flag(self.settings,@"enabled")&&self.sessions.count&&AXIsProcessTrusted();
    if(want&&!self.tap){CGEventMask mask=CGEventMaskBit(kCGEventKeyDown)|CGEventMaskBit(kCGEventKeyUp)|CGEventMaskBit(kCGEventFlagsChanged);self.tap=CGEventTapCreate(kCGSessionEventTap,kCGHeadInsertEventTap,kCGEventTapOptionDefault,mask,DXTap,(__bridge void *)self);if(self.tap){self.tapSource=CFMachPortCreateRunLoopSource(NULL,self.tap,0);CFRunLoopAddSource(CFRunLoopGetMain(),self.tapSource,kCFRunLoopCommonModes);CGEventTapEnable(self.tap,true);}}
    if(!want&&self.tap)[self removeTap];
    for(NSNumber *key in self.bars.allKeys.copy)if(!found[key]||!Flag(self.settings,@"miniBar")){[self.bars[key] close];[self.bars removeObjectForKey:key];[self.collapsed removeObject:key];}
    if(Flag(self.settings,@"miniBar"))for(NSNumber *key in found){NSDictionary *w=found[key];DXMiniPanel *bar=self.bars[key];if(!bar){bar=[self makeBar:w];self.bars[key]=bar;}
        if(self.captureTarget||focus!=[w[@"pid"] intValue]){[bar orderOut:nil];continue;}
        NSRect frame=[w[@"frame"] rectValue]; CGFloat height=[self.collapsed containsObject:key]?42:8*38+6;
        NSScreen *screen=NSScreen.mainScreen;for(NSScreen *candidate in NSScreen.screens)if(NSIntersectsRect(candidate.frame,frame)){screen=candidate;break;}
        NSRect area=screen.visibleFrame;CGFloat x=[self.settings[@"miniSide"] integerValue]==1?NSMinX(frame)-46:NSMaxX(frame)+2;
        if(x+44>NSMaxX(area))x=NSMinX(frame)-46;if(x<NSMinX(area))x=NSMaxX(frame)-44;
        CGFloat y=MIN(MAX(NSMidY(frame)-height/2,NSMinY(area)),NSMaxY(area)-height);
        [bar setFrame:NSMakeRect(x,y,44,height) display:YES];[bar orderFront:nil];
    }
}
- (DXMiniPanel *)makeBar:(NSDictionary *)target {
    DXMiniPanel *p=[[DXMiniPanel alloc] initWithContentRect:NSMakeRect(0,0,44,310) styleMask:NSWindowStyleMaskBorderless|NSWindowStyleMaskNonactivatingPanel backing:NSBackingStoreBuffered defer:NO];p.releasedWhenClosed=NO;p.hidesOnDeactivate=NO;p.level=NSFloatingWindowLevel;p.collectionBehavior=NSWindowCollectionBehaviorCanJoinAllSpaces|NSWindowCollectionBehaviorFullScreenAuxiliary;p.title=[NSString stringWithFormat:@"DX Mini · %@",target[@"mode"]];
    NSArray *symbols=@[@"display.slash",@"display",@"power",@"arrow.up.left.and.arrow.down.right",@"arrow.down.right.and.arrow.up.left",@"camera",@"gearshape",@"chevron.compact.up"];
    NSArray *en=@[@"Phone screen off",@"Phone screen on",@"Power button",@"Fullscreen",@"Original size (fit on screen)",@"Capture window",@"Open DX Manager",@"Collapse / expand"];
    NSArray *ko=@[@"휴대폰 화면 끄기",@"휴대폰 화면 켜기",@"전원 버튼",@"전체화면",@"원래 크기 (화면 안에 맞춤)",@"창 캡처",@"DX Manager 열기",@"접기 / 펼치기"];
    BOOL collapsed=[self.collapsed containsObject:target[@"window"]];
    for(NSInteger i=0;i<8;i++){if(collapsed&&i<7)continue;NSArray *fallback=@[@"OFF",@"ON",@"P",@"↗",@"1:1",@"PNG",@"DX",@"⌃"];NSButton *b=MiniButton([NSImage imageWithSystemSymbolName:symbols[i] accessibilityDescription:(self.korean?ko:en)[i]],fallback[i],self,@selector(miniAction:));b.frame=NSMakeRect(4,collapsed?3:310-(i+1)*38,36,34);b.tag=i;b.identifier=[target[@"window"] stringValue];b.toolTip=(self.korean?ko:en)[i];b.accessibilityLabel=b.toolTip;[p.contentView addSubview:b];}return p;
}
- (void)miniAction:(NSButton *)button {
    NSNumber *key=@(button.identifier.intValue);NSDictionary *target=self.windows[key];if(![self live:target])return;
    if(button.tag==7){if([self.collapsed containsObject:key])[self.collapsed removeObject:key];else[self.collapsed addObject:key];[self.bars[key] close];[self.bars removeObjectForKey:key];[self refresh];return;}
    if(button.tag==6){if(self.showManager)self.showManager();return;}
    if(button.tag==5){[self beginCapture:target direct:YES];return;}
    if(!AXIsProcessTrusted()){[self notify:[self t:@"Allow Accessibility in Keyboard settings to use these controls." ko:@"키 입력 설정에서 손쉬운 사용 권한을 허용해 주세요."]];return;}
    CGKeyCode keys[]={kVK_ANSI_O,kVK_ANSI_O,kVK_ANSI_P,kVK_ANSI_F,kVK_ANSI_G};
    [self chord:keys[button.tag] flags:kCGEventFlagMaskAlternate|(button.tag==1?kCGEventFlagMaskShift:0) target:target];
    if(button.tag==4) {
        // scrcpy MOD+G changes size only. Keep the resulting window inside the
        // original display, after SDL has processed its asynchronous shortcut.
        __weak DXDesktopControls *weak=self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,250*NSEC_PER_MSEC),dispatch_get_main_queue(),^{[weak fitResizedWindow:target];});
    }
}
- (void)fitResizedWindow:(NSDictionary *)target {
    if(![self live:target]||!AXIsProcessTrusted()||NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier!=[target[@"pid"] intValue])return;
    NSRect original=[target[@"frame"] rectValue];NSScreen *screen=nil;CGFloat largest=0;
    for(NSScreen *candidate in NSScreen.screens){NSRect intersection=NSIntersectionRect(candidate.frame,original);CGFloat area=intersection.size.width*intersection.size.height;if(area>largest){largest=area;screen=candidate;}}
    if(!screen)return;
    AXUIElementRef app=AXUIElementCreateApplication([target[@"pid"] intValue]);
    AXUIElementSetMessagingTimeout(app,0.2);
    CFTypeRef value=NULL;
    if(AXUIElementCopyAttributeValue(app,kAXWindowsAttribute,&value)!=kAXErrorSuccess){CFRelease(app);return;}
    NSArray *windows=CFBridgingRelease(value);
    // Do not guess when another window/dialog belongs to the same process.
    if(![windows isKindOfClass:NSArray.class]||windows.count!=1){CFRelease(app);return;}
    AXUIElementRef window=(__bridge AXUIElementRef)windows.firstObject;
    CFTypeRef fullscreen=NULL;BOOL isFullscreen=NO;
    if(AXUIElementCopyAttributeValue(window,CFSTR("AXFullScreen"),&fullscreen)==kAXErrorSuccess){isFullscreen=CFEqual(fullscreen,kCFBooleanTrue);CFRelease(fullscreen);}
    NSRect current;
    if(isFullscreen||!ReadAXFrame(window,&current)){CFRelease(app);return;}
    NSRect area=NSInsetRect(screen.visibleFrame,8,8),fitted=FitWindowFrame(current,area);
    for(NSUInteger attempt=0;attempt<2&&!NSEqualSizes(current.size,fitted.size);attempt++){
        CGSize size=fitted.size;AXValueRef requested=AXValueCreate(kAXValueCGSizeType,&size);
        AXError error=AXUIElementSetAttributeValue(window,kAXSizeAttribute,requested);CFRelease(requested);
        if(error!=kAXErrorSuccess){CFRelease(app);[self notify:[self t:@"Could not fit the DeX window. Resize it using its corner." ko:@"DeX 창 크기를 맞추지 못했습니다. 창 모서리로 조정해 주세요."]];return;}
        // SDL may enforce its video aspect ratio; use the accepted size for position.
        if(!ReadAXFrame(window,&current)){CFRelease(app);return;}
        fitted=FitWindowFrame(current,area);
    }
    if(current.size.width>area.size.width||current.size.height>area.size.height){CFRelease(app);[self notify:[self t:@"DeX did not accept the screen-fitting size. Resize it using its corner." ko:@"DeX가 화면 안에 맞는 크기를 적용하지 못했습니다. 창 모서리로 조정해 주세요."]];return;}
    CGPoint point=CGPointMake(fitted.origin.x,NSMaxY(NSScreen.screens.firstObject.frame)-NSMaxY(fitted));
    AXValueRef position=AXValueCreate(kAXValueCGPointType,&point);
    AXError error=AXUIElementSetAttributeValue(window,kAXPositionAttribute,position);CFRelease(position);CFRelease(app);
    if(error!=kAXErrorSuccess)[self notify:[self t:@"Could not move the DeX window inside the screen." ko:@"DeX 창을 화면 안으로 이동하지 못했습니다."]];
}
- (void)post:(CGKeyCode)key type:(CGEventType)type flags:(CGEventFlags)flags pid:(pid_t)pid {
    CGEventRef event=CGEventCreateKeyboardEvent(NULL,key,type==kCGEventKeyDown);if(!event)return;CGEventSetType(event,type);CGEventSetFlags(event,flags);CGEventSetIntegerValueField(event,kCGEventSourceUserData,DXInjected);CGEventPostToPid(pid,event);CFRelease(event);
}
- (void)chord:(CGKeyCode)key flags:(CGEventFlags)flags target:(NSDictionary *)target {
    if(![self live:target])return;pid_t pid=[target[@"pid"] intValue];
    // Preserve modifiers physically held by the user; only release our additions.
    CGEventFlags physical=CGEventSourceFlagsState(kCGEventSourceStateCombinedSessionState);
    CGEventFlags base=physical & ShortcutFlags;
    if(self.held[@(kVK_RightOption)] && !(physical & NX_DEVICELALTKEYMASK)) base &= ~kCGEventFlagMaskAlternate;
    CGEventFlags added=flags & ~base; flags |= base;
    // Balanced modifier transitions reach SDL without modifying global keyboard state.
    if(added&kCGEventFlagMaskAlternate)[self post:kVK_Option type:kCGEventFlagsChanged flags:base|kCGEventFlagMaskAlternate pid:pid];
    if(added&kCGEventFlagMaskShift)[self post:kVK_Shift type:kCGEventFlagsChanged flags:flags pid:pid];
    [self post:key type:kCGEventKeyDown flags:flags pid:pid];[self post:key type:kCGEventKeyUp flags:flags pid:pid];
    if(added&kCGEventFlagMaskShift)[self post:kVK_Shift type:kCGEventFlagsChanged flags:flags&~kCGEventFlagMaskShift pid:pid];
    if(added&kCGEventFlagMaskAlternate)[self post:kVK_Option type:kCGEventFlagsChanged flags:base pid:pid];
}
- (CGEventFlags)releasedFlags:(NSInteger)mapped {
    CGEventFlags flags=CGEventSourceFlagsState(kCGEventSourceStateCombinedSessionState);
    if(mapped==kVK_Shift) {flags &= ~NX_DEVICERSHIFTKEYMASK;if(!(flags&NX_DEVICELSHIFTKEYMASK))flags &= ~kCGEventFlagMaskShift;}
    if(mapped==kVK_Command) {flags &= ~NX_DEVICERCMDKEYMASK;if(!(flags&NX_DEVICELCMDKEYMASK))flags &= ~kCGEventFlagMaskCommand;}
    return flags;
}
- (void)releaseHeld {
    for(NSDictionary *entry in self.held.allValues){NSInteger mapped=[entry[@"mapped"] integerValue];if(mapped>=0)[self post:(CGKeyCode)mapped type:Flag(entry,@"modifier")?kCGEventFlagsChanged:kCGEventKeyUp flags:[self releasedFlags:mapped] pid:[entry[@"pid"] intValue]];}
    [self.held removeAllObjects];
}
- (void)removeTap {[self releaseHeld];if(self.tap){CGEventTapEnable(self.tap,false);if(self.tapSource){CFRunLoopRemoveSource(CFRunLoopGetMain(),self.tapSource,kCFRunLoopCommonModes);CFRelease(self.tapSource);self.tapSource=NULL;}CFMachPortInvalidate(self.tap);CFRelease(self.tap);self.tap=NULL;}}
- (CGEventRef)event:(CGEventRef)event type:(CGEventType)type {
    if(type==kCGEventTapDisabledByTimeout||type==kCGEventTapDisabledByUserInput){[self releaseHeld];if(self.tap)CGEventTapEnable(self.tap,true);return event;}
    if(CGEventGetIntegerValueField(event,kCGEventSourceUserData)==DXInjected)return event;
    CGKeyCode key=(CGKeyCode)CGEventGetIntegerValueField(event,kCGKeyboardEventKeycode);CGEventFlags flags=CGEventGetFlags(event);
    BOOL modifier=type==kCGEventFlagsChanged;BOOL down=type==kCGEventKeyDown;
    if(modifier){if(key==kVK_RightOption)down=(flags&NX_DEVICERALTKEYMASK)!=0;else if(key==kVK_RightShift)down=(flags&NX_DEVICERSHIFTKEYMASK)!=0;else if(key==kVK_RightCommand)down=(flags&NX_DEVICERCMDKEYMASK)!=0;else return event;}
    NSDictionary *held=self.held[@(key)];
    if(!down&&held){[self.held removeObjectForKey:@(key)];NSInteger mapped=[held[@"mapped"] integerValue];if(mapped>=0){CGEventFlags out=[held[@"flags"] unsignedLongLongValue];if(modifier)out=[self releasedFlags:mapped];[self post:(CGKeyCode)mapped type:modifier?kCGEventFlagsChanged:kCGEventKeyUp flags:out pid:[held[@"pid"] intValue]];}return NULL;}
    if(self.captureTarget){if(key==kVK_Escape&&down){dispatch_async(dispatch_get_main_queue(),^{[self cancelCapture];});return NULL;}if(Shortcut(Str(self.settings[@"captureHotkey"]),key,flags)){if(down&&!CGEventGetIntegerValueField(event,kCGKeyboardEventAutorepeat)){NSDictionary *target=self.captureTarget;dispatch_async(dispatch_get_main_queue(),^{[self cancelCapture];[self beginCapture:target direct:YES];});}return NULL;}return event;}
    NSDictionary *target=self.focusedWindow;if(!target)return event;
    if(self.held[@(kVK_RightOption)] && !(flags&NX_DEVICELALTKEYMASK)) flags &= ~(kCGEventFlagMaskAlternate|NX_DEVICERALTKEYMASK);
    if(self.held[@(kVK_RightShift)]) flags=(flags&~NX_DEVICERSHIFTKEYMASK)|NX_DEVICELSHIFTKEYMASK|kCGEventFlagMaskShift;
    if(self.held[@(kVK_RightCommand)]) flags=(flags&~NX_DEVICERCMDKEYMASK)|NX_DEVICELCMDKEYMASK|kCGEventFlagMaskCommand;
    CGEventSetFlags(event,flags);
    if(held)return NULL;
    if(!down)return event;
    BOOL repeat=CGEventGetIntegerValueField(event,kCGKeyboardEventAutorepeat)!=0;
    NSString *action=nil;NSInteger mapped=-1;CGEventFlags out=flags;
    if(Shortcut(Str(self.settings[@"captureHotkey"]),key,flags))action=@"capture";
    else if(Shortcut(Str(self.settings[@"exitHotkey"]),key,flags))action=@"session-stop";
    else if(key==kVK_F14&&Flag(self.settings,@"enter"))action=@"toggle-enter";
    else if(key==kVK_RightOption&&Flag(self.settings,@"hangul"))action=@"hangul";
    else if(key==kVK_Space&&(flags&kCGEventFlagMaskShift)&&Flag(self.settings,@"ignoreShiftSpace"))action=@"ignore";
    else if(key==kVK_Return&&Flag(self.settings,@"enter")&&[self.enterModes[target[@"pid"]] boolValue])action=@"enter";
    else if(key==kVK_RightShift){mapped=kVK_Shift;out=(flags&~NX_DEVICERSHIFTKEYMASK)|NX_DEVICELSHIFTKEYMASK|kCGEventFlagMaskShift;}
    else if(key==kVK_RightCommand&&Flag(self.settings,@"rightCommand")){mapped=kVK_Command;out=(flags&~NX_DEVICERCMDKEYMASK)|NX_DEVICELCMDKEYMASK|kCGEventFlagMaskCommand;}
    else return event;
    self.held[@(key)]=@{@"pid":target[@"pid"],@"mapped":@(mapped),@"flags":@(out),@"modifier":@(modifier)};
    if(mapped>=0){[self post:(CGKeyCode)mapped type:modifier?kCGEventFlagsChanged:kCGEventKeyDown flags:out pid:[target[@"pid"] intValue]];return NULL;}
    if(repeat)return NULL;
    dispatch_async(dispatch_get_main_queue(),^{
        if(![self live:target]||NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier!=[target[@"pid"] intValue])return;
        if([action isEqual:@"capture"])[self beginCapture:target direct:NO];
        else if([action isEqual:@"toggle-enter"]){BOOL mode=![self.enterModes[target[@"pid"]] boolValue];self.enterModes[target[@"pid"]]=@(mode);[self notify:mode?@"Shift+Enter":@"Enter"];}
        else if([action isEqual:@"hangul"]||[action isEqual:@"enter"]){NSString *setting=[action isEqual:@"hangul"]?@"hangulMode":@"enterMode";if([self.settings[setting] intValue]==2){if(self.command)self.command(@"key-input",target,@{@"key":action});}else[self chord:[action isEqual:@"hangul"]?kVK_Space:kVK_Return flags:kCGEventFlagMaskShift target:target];}
        else if([action isEqual:@"session-stop"]&&self.command)self.command(action,target,@{});
    });return NULL;
}
- (void)beginCapture:(NSDictionary *)target direct:(BOOL)direct {
    if(self.captureBusy||![self live:target])return;
    if(!CGPreflightScreenCaptureAccess()){[self notify:[self t:@"Allow Screen Recording in Keyboard settings before capturing." ko:@"캡처 전에 키 입력 설정에서 화면 기록 권한을 허용해 주세요."]];return;}
    [self cancelCapture];self.captureBusy=YES;self.captureTarget=target;NSUInteger generation=++self.captureGeneration;
    for(NSPanel *bar in self.bars.allValues)[bar orderOut:nil];
    [SCShareableContent getShareableContentExcludingDesktopWindows:YES onScreenWindowsOnly:YES completionHandler:^(SCShareableContent *content,NSError *error){
        SCWindow *window=nil;for(SCWindow *w in content.windows)if(w.windowID==[target[@"window"] unsignedIntValue]&&w.owningApplication.processID==[target[@"pid"] intValue]){window=w;break;}
        if(error||!window){dispatch_async(dispatch_get_main_queue(),^{if(generation!=self.captureGeneration)return;[self cancelCapture];[self notify:error.localizedDescription?:[self t:@"Capture window no longer exists." ko:@"캡처 대상 창이 닫혔습니다."]];});return;}
        SCContentFilter *filter=[[SCContentFilter alloc] initWithDesktopIndependentWindow:window];SCStreamConfiguration *cfg=[[SCStreamConfiguration alloc] init];cfg.width=(size_t)ceil(window.frame.size.width*filter.pointPixelScale);cfg.height=(size_t)ceil(window.frame.size.height*filter.pointPixelScale);cfg.showsCursor=NO;cfg.ignoreShadowsSingleWindow=YES;
        [SCScreenshotManager captureImageWithFilter:filter configuration:cfg completionHandler:^(CGImageRef image,NSError *imageError){
            NSBitmapImageRep *bitmap=image?[[NSBitmapImageRep alloc] initWithCGImage:image]:nil;
            dispatch_async(dispatch_get_main_queue(),^{if(generation!=self.captureGeneration)return;self.captureBusy=NO;if(imageError||!bitmap||![self live:target]){[self cancelCapture];[self notify:imageError.localizedDescription?:[self t:@"Capture failed; no image saved." ko:@"캡처에 실패해 파일을 저장하지 않았습니다."]];return;}
                if(direct){[self saveBitmap:bitmap target:target];[self cancelCapture];}else[self selectRegion:bitmap target:target];
            });
        }];
    }];
}
- (void)selectRegion:(NSBitmapImageRep *)bitmap target:(NSDictionary *)target {
    NSRect frame=[target[@"frame"] rectValue];self.overlay=[[DXCapturePanel alloc] initWithContentRect:frame styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];self.overlay.releasedWhenClosed=NO;self.overlay.level=NSFloatingWindowLevel+1;self.overlay.collectionBehavior=NSWindowCollectionBehaviorFullScreenAuxiliary;
    DXSelectionView *view=[[DXSelectionView alloc] initWithFrame:NSMakeRect(0,0,frame.size.width,frame.size.height)];view.image=[[NSImage alloc] initWithSize:frame.size];[view.image addRepresentation:bitmap];view.hint=[NSString stringWithFormat:[self t:@"%@ again: whole window · Drag: region · Esc: cancel (%@ s)" ko:@"%@ 다시: 전체 창 · 드래그: 영역 · Esc: 취소 (%@초)"],self.settings[@"captureHotkey"],self.settings[@"captureWait"]];
    __weak DXDesktopControls *weak=self;
    view.cancelled=^{[weak cancelCapture];};view.full=^{[weak cancelCapture];[weak beginCapture:target direct:YES];};
    view.selected=^(NSRect rect){DXDesktopControls *strong=weak;if(![strong live:target]){[strong cancelCapture];return;}CGFloat sx=bitmap.pixelsWide/frame.size.width,sy=bitmap.pixelsHigh/frame.size.height;CGRect crop=CGRectMake(floor(rect.origin.x*sx),floor(rect.origin.y*sy),ceil(rect.size.width*sx),ceil(rect.size.height*sy));CGImageRef cropped=CGImageCreateWithImageInRect(bitmap.CGImage,crop);if(cropped){[strong saveBitmap:[[NSBitmapImageRep alloc] initWithCGImage:cropped] target:target];CGImageRelease(cropped);}[strong cancelCapture];};
    self.overlay.contentView=view;[self.overlay makeKeyAndOrderFront:nil];[self.overlay makeFirstResponder:view];[NSApp activateIgnoringOtherApps:YES];
    self.captureTimer=[NSTimer scheduledTimerWithTimeInterval:MAX(1,[self.settings[@"captureWait"] doubleValue]) repeats:NO block:^(NSTimer *timer){(void)timer;[weak cancelCapture];}];
}
- (void)saveBitmap:(NSBitmapImageRep *)bitmap target:(NSDictionary *)target {
    if(![self live:target])return;NSString *folder=Str(self.settings[@"screenshotFolder"]);if(!folder.isAbsolutePath){[self notify:@"Invalid screenshot folder."];return;}
    NSError *error=nil;[NSFileManager.defaultManager createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:&error];
    NSString *path=[folder stringByAppendingPathComponent:[NSString stringWithFormat:@"DXM_%@.png",NSUUID.UUID.UUIDString]];
    NSData *png=[bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    if(error||!png||![png writeToFile:path options:NSDataWritingWithoutOverwriting error:&error]){[self notify:error.localizedDescription?:@"Could not save PNG."];return;}
    [self notify:[NSString stringWithFormat:[self t:@"Saved: %@" ko:@"저장: %@"],path]];
    if(self.command)self.command(@"capture-finish",target,@{@"path":path});
}
- (void)cancelCapture {self.captureGeneration++;self.captureBusy=NO;NSDictionary *target=self.captureTarget;self.captureTarget=nil;[self.captureTimer invalidate];self.captureTimer=nil;[self.overlay close];self.overlay=nil;
    if(target&&self.running&&NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier==NSProcessInfo.processInfo.processIdentifier)[[NSRunningApplication runningApplicationWithProcessIdentifier:[target[@"pid"] intValue]] activateWithOptions:0];
}
- (void)stop {self.running=NO;[self.timer invalidate];self.timer=nil;[self cancelCapture];[self removeTap];for(NSPanel *p in self.bars.allValues)[p close];[self.bars removeAllObjects];[self.enterModes removeAllObjects];}
@end
static CGEventRef DXTap(CGEventTapProxy proxy,CGEventType type,CGEventRef event,void *context){(void)proxy;return [(__bridge DXDesktopControls *)context event:event type:type];}
