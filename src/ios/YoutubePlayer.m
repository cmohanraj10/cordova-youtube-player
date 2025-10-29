#import "YoutubePlayer.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "XCDYouTubeKit/XCDYouTubeKit.h" 
// Note: This file should be placed in your plugin directory: src/ios/

@implementation YoutubePlayer

- (void)playVideo:(CDVInvokedUrlCommand*)command
{
    // Ensure this runs on the main thread for UI elements (like presenting the player)
    // The XCDYouTubeClient call automatically handles background networking.
    
    // 1. Retrieve the video ID from the JavaScript arguments
    NSString *videoId = [command.arguments objectAtIndex:0];
    
    if (!videoId || [videoId length] == 0) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Video ID is required."];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }
    
    // 2. Use XCDYouTubeKit to get the stream URL (done in background thread by the library)
    // The completionHandler block will execute on the main thread (or a background thread, 
    // depending on the library's implementation; we use dispatch_async to ensure UI is updated on main).
    
    [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:videoId completionHandler:^(XCDYouTubeVideo * _Nullable video, NSError * _Nullable error) {
        
        // Switch to the main thread for UI updates (presenting the player)
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (video) {
                // 3. FIX: Use the fully compatible Objective-C syntax (objectForKey:) 
                // to access the streamURLs dictionary, which resolves the ARC conversion error.
                NSDictionary *streamURLs = video.streamURLs;
                
                // Prioritize 720p, fallback to 360p
                // 🌟 THIS IS THE CORRECTED LINE 🌟
                NSURL *videoURL = [streamURLs objectForKey:XCDYouTubeVideoQualityHD720] ?: [streamURLs objectForKey:XCDYouTubeVideoQualityMedium360];
                
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
}

@end