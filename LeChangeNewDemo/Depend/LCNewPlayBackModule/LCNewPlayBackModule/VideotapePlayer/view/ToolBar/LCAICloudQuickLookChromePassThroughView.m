#import "LCAICloudQuickLookChromePassThroughView.h"

@implementation LCAICloudQuickLookChromePassThroughView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *v = [super hitTest:point withEvent:event];
    return v == self ? nil : v;
}

@end
