var exec = require('cordova/exec');

/**
 * Public facing API: window.YoutubePlayer.openVideo('VIDEO_ID', success, error)
 */
exports.openVideo = function(videoId, successCallback, errorCallback) {
    
    // Simple validation
    if (typeof videoId !== 'string' || videoId.length === 0) {
        if (errorCallback) {
            errorCallback('Video ID is required.');
        }
        return;
    }

    // Call the native side via the Cordova bridge
    exec(
        successCallback,      // Success function
        errorCallback,        // Error function
        'YoutubePlayer',      // Native Service Name
        'playVideo',          // Native Method Name
        [videoId]             // Arguments array
    );
};