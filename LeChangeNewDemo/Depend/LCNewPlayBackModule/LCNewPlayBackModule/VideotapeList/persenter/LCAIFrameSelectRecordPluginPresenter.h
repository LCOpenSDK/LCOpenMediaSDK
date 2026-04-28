#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <LCOpenMediaSDK/LCOpenMediaSDK.h>
#import <LCOpenMediaSDK/LCOpenMediaSDK-Swift.h>
#import "LCAIQuickLookPlaybackTypes.h"

NS_ASSUME_NONNULL_BEGIN

/// MVP：承接 `LCOpenMediaRecordPlugin` 回调，向每日帧选播放 View（`LCAIFrameSelectPlaybackViewController`）派发业务状态与进度时间
@interface LCAIFrameSelectRecordPluginPresenter : NSObject <LCRecordPluginDelegate, LCRecordPluginGestureDelegate, LCRecordDoubleCamWindowDelegate>

@property (nonatomic, weak, nullable) LCOpenMediaRecordPlugin *recordPlugin;
@property (nonatomic, copy, nullable) void (^onBizState)(LCAICloudQuickLookBizScene scene, NSString *_Nullable message);
@property (nonatomic, copy, nullable) void (^onRefresh)(void);
@property (nonatomic, copy, nullable) void (^onPlayTime)(NSTimeInterval t);
@property (nonatomic, assign) BOOL expectFirstSDKLoading;

@end

NS_ASSUME_NONNULL_END
