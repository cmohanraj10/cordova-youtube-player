#import "YoutubePlayer.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "XCDYouTubeKit/XCDYouTubeKit.h" 

@implementation YoutubePlayer

// ... (unchanged code for playVideo: and videoId retrieval) ...

- (void)playVideo:(CDVInvokedUrlCommand*)command
{
    // ... (videoId retrieval and validation) ...
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
                
                // 🌟 DEFINITIVE FIX: Use the dictionary to manually fetch the best quality. 🌟
                // We prioritize the keys that are most likely to exist as NSStrings in the specific Pod version.
                // NOTE: Keys like XCDYouTubeVideoQualityHD720 are NSString * in the headers.
                // We use objectForKey: to manually select and ensure the key is treated as an object.
                
                // Try 720p, fallback to 360p, then lowest available quality key (XCDYouTubeVideoQualitySmall240)
                NSURL *videoURL = [streamURLs objectForKey:XCDYouTubeVideoQualityHD720] ?: 
                                  [streamURLs objectForKey:XCDYouTubeVideoQualityMedium360] ?:
                                  [streamURLs objectForKey:XCDYouTubeVideoQualitySmall240]; 
                
                if (videoURL) {
                    
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