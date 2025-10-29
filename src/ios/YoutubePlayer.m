#import "YoutubePlayer.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "XCDYouTubeKit/XCDYouTubeKit.h" 

@implementation YoutubePlayer

- (void)playVideo:(CDVInvokedUrlCommand*)command
{
    // ... (unchanged code for videoId retrieval) ...
    NSString *videoId = [command.arguments objectAtIndex:0];
    
    if (!videoId || [videoId length] == 0) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Video ID is required."];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }
    
    [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:videoId completionHandler:^(XCDYouTubeVideo * _Nullable video, NSError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (video) {
                
                NSDictionary *streamURLs = video.streamURLs;
                
                // 🌟 DEFINITIVE FIX: Explicitly cast to (id) 🌟
                // The compiler MUST accept (id) as the key type for NSDictionary access.
                NSURL *videoURL = [streamURLs objectForKey:(id)XCDYouTubeVideoQualityHD720] ?: [streamURLs objectForKey:(id)XCDYouTubeVideoQualityMedium360];
                
                if (videoURL) {
                    // ... (rest of the successful playback code) ...
                    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
                    playerViewController.player = [AVPlayer playerWithURL:videoURL];
                    
                    [self.viewController presentViewController:playerViewController animated:YES completion:^{
                        [playerViewController.player play];
                        
                        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                    }];
                } else {
                    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Could not find a playable stream URL."];
                    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                }
            } else {
                CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"XCDYouTubeKit Error: %@", error.localizedDescription]];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }
        });
    }];
}

@end