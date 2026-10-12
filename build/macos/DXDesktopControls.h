#import <AppKit/AppKit.h>
@interface DXDesktopControls : NSObject
@property(copy) void (^command)(NSString *, NSDictionary *, NSDictionary *);
@property(copy) void (^message)(NSString *);
@property(copy) void (^showManager)(void);
- (void)configure:(NSDictionary *)settings language:(NSInteger)language;
- (void)setSessions:(NSArray<NSDictionary *> *)sessions;
- (NSString *)permissionStatus;
- (void)requestAccessibility;
- (void)requestScreenCapture;
- (void)stop;
@end
