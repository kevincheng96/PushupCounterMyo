#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
@class ViewController;
@interface TestAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ViewController *viewController;

- (void) loadCaptureSessionView;

@end