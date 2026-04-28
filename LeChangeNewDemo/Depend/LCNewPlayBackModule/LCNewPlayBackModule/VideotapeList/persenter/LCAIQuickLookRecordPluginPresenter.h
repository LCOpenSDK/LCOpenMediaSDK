#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LCAIQuickLookPlaybackTypes.h"
#import <LCOpenMediaSDK/LCOpenMediaSDK.h>
#import <LCOpenMediaSDK/LCOpenMediaSDK-Swift.h>

NS_ASSUME_NONNULL_BEGIN

/// MVP：承接 `LCOpenMediaRecordPlugin` 播放/手势/双摄回调，向每日影集 View（`LCAICloudEventListViewController`）派发业务状态与时间轴
@interface LCAIQuickLookRecordPluginPresenter : NSObject <LCRecordPluginDelegate, LCRecordDoubleCamWindowDelegate, LCRecordPluginGestureDelegate>

@property (nonatomic, weak, nullable) LCOpenMediaRecordPlugin *recordPlugin;
@property (nonatomic, weak) UIViewController *hostViewController;
@property (nonatomic, copy, nullable) void (^onPlayTime)(NSTimeInterval t);
@property (nonatomic, copy, nullable) void (^onChromeRefresh)(void);
@property (nonatomic, copy, nullable) void (^onBizState)(LCAICloudQuickLookBizScene scene, NSString *_Nullable message);
@property (nonatomic, assign) BOOL expectFirstSDKLoadingEvent;
@property (nonatomic, copy, nullable) void (^onDoubleTapVideo)(NSInteger cid);
@property (nonatomic, copy, nullable) void (^onSingleTapVideo)(NSInteger cid);

- (instancetype)initWithHostViewController:(UIViewController *)hostViewController onPlayTime:(void (^)(NSTimeInterval))onPlayTime;
- (void)resetExpectFirstSDKLoadingForNewPlay;

@end

NS_ASSUME_NONNULL_END
