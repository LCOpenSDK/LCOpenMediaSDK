#ifndef LCAICloudAppBundleImage_h
#define LCAICloudAppBundleImage_h

#import <UIKit/UIKit.h>

/// 与 `LCAICloudQuickLookSummaryListCell` 一致：每日快看 / 每日帧选 等资源放在宿主 `Assets.xcassets`，framework 内须用 `mainBundle` 读取。
static inline UIImage *_Nullable LCAICloudAppBundleImage(NSString *_Nonnull name) {
    if (name.length == 0) {
        return nil;
    }
    UIImage *img = [UIImage imageNamed:name inBundle:NSBundle.mainBundle compatibleWithTraitCollection:nil];
    if (!img) {
        img = [UIImage imageNamed:name];
    }
    return img;
}

#endif
