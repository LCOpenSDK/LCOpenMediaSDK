#import "LCAICloudQuickLookPlayerToolbarIcons.h"
#import "LCAICloudAppBundleImage.h"

@implementation LCAICloudQuickLookPlayerToolbarIcons

+ (UIImage *)portraitPlayImage {
    return LCAICloudAppBundleImage(@"video_fullscreen_btn_pause_n");
}

+ (UIImage *)portraitPauseImage {
    return LCAICloudAppBundleImage(@"video_fullscreen_btn_play_n");
}

+ (UIImage *)portraitVoiceOnImage {
    return LCAICloudAppBundleImage(@"video_fullscreen_btn_voice_on_n");
}

+ (UIImage *)portraitVoiceOffImage {
    return LCAICloudAppBundleImage(@"video_fullscreen_btn_mute_n");
}

+ (UIImage *)portraitScreenshotImage {
    return LCAICloudAppBundleImage(@"video_fullscreen_btn_screenshot_n");
}

+ (UIImage *)portraitRecordImage {
    return LCAICloudAppBundleImage(@"video_fullscreen_btn_record_n");
}

+ (UIImage *)portraitFullscreenImage {
    return LCAICloudAppBundleImage(@"video_live_fullscreen");
}

+ (UIImage *)portraitDownloadImage {
    return LCAICloudAppBundleImage(@"video_playvideo_download");
}

@end
