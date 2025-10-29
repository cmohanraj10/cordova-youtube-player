#import "YoutubePlayer.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "XCDYouTubeKit/XCDYouTubeKit.h" // The pod dependency

@implementation YoutubePlayer

- (void)playVideo:(CDVInvokedUrlCommand*)command
{
    // 1. Retrieve the video ID from the JavaScript arguments
    NSString *videoId = [command.arguments objectAtIndex:0];
    
    if (!videoId || [videoId length] == 0) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Video ID is required."];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }
    
    // 2. Use XCDYouTubeKit to get the stream URL (done in background thread)
    [self.commandDelegate runInBackground:^{
        
        [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:videoId completionHandler:^(XCDYouTubeVideo * _Nullable video, NSError * _Nullable error) {
            
            // Switch back to the main thread for UI updates
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (video) {
                    // 3. Select a suitable stream URL (720p preferred, falling back to 360p)
                    NSDictionary *streamURLs = video.streamURLs;
                    NSURL *videoURL = streamURLs[XCDYouTubeVideoQualityHD720] ?: streamURLs[XCDYouTubeVideoQualityMedium360];
                    
                    if (videoURL) {
                        // 4. Initialize and present the native AVPlayer
                        AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
                        playerViewController.player = [AVPlayer playerWithURL:videoURL];
                        
                        [self.viewController presentViewController:playerViewController animated:YES completion:^{
                            [playerViewController.player play];
                            
                            // Send success back to JavaScript
                            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                        }];
                    } else {
                        // Stream URL not found (e.g., restricted video)
                        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Could not find a playable stream URL."];
                        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                    }
                } else {
                    // XCDYouTubeKit extraction failed
                    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"XCDYouTubeKit Error: %@", error.localizedDescription]];
                    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                }
            });
        }];
    }];
}

@end