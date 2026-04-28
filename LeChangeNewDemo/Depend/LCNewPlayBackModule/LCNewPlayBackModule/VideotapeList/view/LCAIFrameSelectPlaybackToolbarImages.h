#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 每日帧选单条录像播放工具栏黑标：宿主 `LeChangeDemo/Assets.xcassets/LCNewPlayBack_AICloud` 内 `lc_frameselect_tb_*`（与 `LCAICloudQuickLookSummaryListCell` 相同走 `mainBundle`）。
@interface LCAIFrameSelectPlaybackToolbarImages : NSObject
+ (nullable UIImage *)pauseImage;
+ (nullable UIImage *)playImage;
+ (nullable UIImage *)voiceOnImage;
+ (nullable UIImage *)voiceOffImage;
+ (nullable UIImage *)downloadImage;
+ (nullable UIImage *)fullscreenImage;
@end

NS_ASSUME_NONNULL_END
