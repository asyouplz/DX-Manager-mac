// Headless policy regression checks. All event output is intercepted below;
// these tests never install an event tap, open windows or post keyboard events.
#import "../DXDesktopControls.m"
@interface DXTestDesktop : DXDesktopControls
@property NSDictionary *testWindow;
@property NSMutableArray<NSDictionary *> *posted;
@end
@implementation DXTestDesktop
- (void)refresh {}
- (NSDictionary *)focusedWindow { return self.testWindow; }
- (void)post:(CGKeyCode)key type:(CGEventType)type flags:(CGEventFlags)flags pid:(pid_t)pid { [self.posted addObject:@{@"key":@(key),@"type":@(type),@"flags":@(flags),@"pid":@(pid)}]; }
- (CGEventFlags)releasedFlags:(NSInteger)mapped { (void)mapped; return 0; }
@end
static NSUInteger checks=0;
static void Check(BOOL okay,NSString *name){checks++;if(!okay){fprintf(stderr,"FAIL: %s\n",name.UTF8String);exit(1);}}
int main(void){@autoreleasepool {
    [NSApplication sharedApplication];
    NSButton *fallback=MiniButton(nil,@"OFF",nil,NULL);
    Check(fallback!=nil && [fallback.title isEqual:@"OFF"],@"unavailable SF Symbol retains a usable text button");

    NSRect area=NSMakeRect(8,38,1496,870);
    NSRect normal=NSMakeRect(20,50,900,600);
    Check(NSEqualRects(FitWindowFrame(normal,area),normal),@"fitting 1:1 window remains unchanged");
    NSRect overflow=FitWindowFrame(NSMakeRect(1000,300,900,600),area);
    Check(NSContainsRect(area,overflow)&&NSEqualSizes(overflow.size,normal.size),@"right overflow moves inside without shrinking");
    NSRect oversized=FitWindowFrame(NSMakeRect(200,300,1920,1080),area);
    Check(NSContainsRect(area,oversized)&&oversized.size.width<1920,@"oversized window fits usable Retina point bounds");
    NSRect external=NSMakeRect(-1912,-1042,1904,1010);
    Check(NSContainsRect(external,FitWindowFrame(NSMakeRect(-2200,-1200,1400,900),external)),@"negative-origin external display is preserved");
    Check(NSEqualRects(FitWindowFrame(normal,NSZeroRect),normal),@"unavailable screen does not invent bounds");

    Check(Shortcut(@"LeftAlt+F8",kVK_F8,kCGEventFlagMaskAlternate),@"legacy shortcut alias");
    Check(!Shortcut(@"F8",kVK_F8,kCGEventFlagMaskCommand),@"extra modifier is not captured");
    Check(Shortcut(@"ctrl+shift+F12",kVK_F12,kCGEventFlagMaskControl|kCGEventFlagMaskShift),@"combined modifiers");
    DXTestDesktop *d=[DXTestDesktop new];d.posted=[NSMutableArray array];d.settings=@{@"rightCommand":@YES};d.testWindow=@{@"pid":@81234,@"window":@42};
    CGEventRef event=CGEventCreateKeyboardEvent(NULL,kVK_RightShift,true);CGEventSetType(event,kCGEventFlagsChanged);CGEventSetFlags(event,kCGEventFlagMaskShift|NX_DEVICERSHIFTKEYMASK);
    Check([d event:event type:kCGEventFlagsChanged]==NULL,@"right shift consumed");Check(d.posted.count==1&&[d.posted[0][@"key"] intValue]==kVK_Shift,@"left shift delivered to owned process");
    d.testWindow=nil;CGEventSetFlags(event,0);Check([d event:event type:kCGEventFlagsChanged]==NULL,@"release still owned after focus loss");Check(d.posted.count==2&&[d.posted[1][@"pid"] intValue]==81234,@"release routed to original owner");Check(d.held.count==0,@"no latched key");
    Check([d event:event type:kCGEventFlagsChanged]==event,@"foreign window untouched");
    d.testWindow=@{@"pid":@81234};CGEventSetFlags(event,kCGEventFlagMaskShift|NX_DEVICERSHIFTKEYMASK);CGEventSetIntegerValueField(event,kCGEventSourceUserData,DXInjected);NSUInteger count=d.posted.count;Check([d event:event type:kCGEventFlagsChanged]==event&&d.posted.count==count,@"injected event not reprocessed");
    CGEventSetIntegerValueField(event,kCGEventSourceUserData,0);[d event:event type:kCGEventFlagsChanged];[d releaseHeld];Check(d.held.count==0&&[d.posted.lastObject[@"flags"] intValue]==0,@"focus/session cleanup balances held modifier");
    [d stop];CFRelease(event);printf("Desktop controls: %lu windowless routing/shortcut/button checks passed.\n",(unsigned long)checks);
}return 0;}
