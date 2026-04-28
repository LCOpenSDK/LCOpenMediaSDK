#import <Foundation/Foundation.h>

/// 每日影集（原每日快看）与每日帧选播放页共用的业务遮罩 / 工具栏联动状态
typedef NS_ENUM(NSInteger, LCAICloudQuickLookBizScene) {
    LCAICloudQuickLookBizSceneNone = 0,
    LCAICloudQuickLookBizScenePlay,
    LCAICloudQuickLookBizSceneFirstLoading,
    LCAICloudQuickLookBizSceneLoading,
    LCAICloudQuickLookBizSceneRetry,
    LCAICloudQuickLookBizSceneReplay,
};
