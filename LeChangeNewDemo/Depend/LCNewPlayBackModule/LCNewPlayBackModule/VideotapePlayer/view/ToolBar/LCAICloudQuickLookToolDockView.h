#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LCAICloudQuickLookToolDockView : UIView

@property (nonatomic, strong, readonly) CAGradientLayer *gradientLayer;
@property (nonatomic, strong, readonly) UIScrollView *toolScrollView;
@property (nonatomic, strong, readonly) UIStackView *toolStack;
@property (nonatomic, strong, readonly) UIView *fullscreenSlot;

- (void)layoutGradientIfNeeded;
- (void)applyLandscapeLayout:(BOOL)landscape;
- (void)applyLandscapeCloudPlaybackChrome:(BOOL)on embeddedProcessView:(nullable UIView *)processView;

@end

NS_ASSUME_NONNULL_END
