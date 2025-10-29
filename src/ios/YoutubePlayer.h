#import <Cordova/CDVPlugin.h>

@interface YoutubePlayer : CDVPlugin

// Method declared to be called from JavaScript
- (void)playVideo:(CDVInvokedUrlCommand*)command;

@end