#import "LCAIFrameSelectPlaybackToolbarImages.h"
#import "LCAICloudAppBundleImage.h"

@implementation LCAIFrameSelectPlaybackToolbarImages

+ (nullable UIImage *)pauseImage {
    return LCAICloudAppBundleImage(@"lc_frameselect_tb_pause");
}

+ (nullable UIImage *)playImage {
    return LCAICloudAppBundleImage(@"lc_frameselect_tb_play");
}

+ (nullable UIImage *)voiceOnImage {
    return LCAICloudAppBundleImage(@"lc_frameselect_tb_voice_on");
}

+ (nullable UIImage *)voiceOffImage {
    return LCAICloudAppBundleImage(@"lc_frameselect_tb_voice_off");
}

+ (nullable UIImage *)downloadImage {
    return LCAICloudAppBundleImage(@"lc_frameselect_tb_download_portrait");
}

+ (nullable UIImage *)fullscreenImage {
    return LCAICloudAppBundleImage(@"lc_frameselect_tb_fullscreen");
}

@end
