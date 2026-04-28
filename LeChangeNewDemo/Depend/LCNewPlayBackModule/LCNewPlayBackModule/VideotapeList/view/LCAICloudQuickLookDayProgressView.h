#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^LCAICloudQuickLookDayProgressFloatDateBlock)(float offsetSeconds, NSDate *wallDate);

@interface LCAICloudQuickLookDayProgressView : UIView

@property (nonatomic, copy, nullable) LCAICloudQuickLookDayProgressFloatDateBlock valueChangeBlock;
@property (nonatomic, copy, nullable) LCAICloudQuickLookDayProgressFloatDateBlock valueChangeEndBlock;

@property (nonatomic) BOOL canRefreshSlider;

@property (nonatomic, strong, nullable) NSDate *currentDate;

@property (nonatomic, copy, nullable) BOOL (^interactionAllowedBlock)(void);

@property (nonatomic, assign) BOOL isLandscapeLayout;

/// 竖屏且非横屏布局时：浅灰轨道 + 主题色进度（白底工具栏下）；横屏布局时仍用播放器内半透明白轨样式。
@property (nonatomic, assign) BOOL portraitLightChrome;

- (void)setStartDate:(NSDate *)startDate endDate:(NSDate *)endDate;

- (void)setSegmentOverlayRatios:(NSArray<NSNumber *> * _Nullable)ratios;

/// 自然播放结束时末帧时间可能未回调到 `endDate`，将进度与拇指置满轨
- (void)lc_snapProgressToFull;

@end

NS_ASSUME_NONNULL_END
