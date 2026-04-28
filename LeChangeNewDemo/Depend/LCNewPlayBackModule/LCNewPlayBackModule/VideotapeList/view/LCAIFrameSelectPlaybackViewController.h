#import <UIKit/UIKit.h>
#import <LCNetworkModule/LCCloudVideotapeInfo.h>

NS_ASSUME_NONNULL_BEGIN

/// 每日帧选单条录像播放（与每日快看同 SDK 拉流；竖屏白底工具栏含下载 + 灰底主题色进度条，横屏渐变 dock 内嵌进度条与快看一致；无抓图/录制；业务遮罩与工具栏联动与快看对齐）
@interface LCAIFrameSelectPlaybackViewController : UIViewController

@property (nonatomic, strong) LCCloudVideotapeInfo *cloudRecord;
/// 与 `LCAIFrameSelectEventListViewController` 当前选中通道一致（`persenter.selectedChannelId`）；未设置时回退 `cloudRecord.channelId`
@property (nonatomic, copy) NSString *playbackChannelId;
/// 在整段云录像内的起始偏移（秒），与 LCAICloud `playCondensed` 一致
@property (nonatomic, assign) double initialOffsetSeconds;

@end

NS_ASSUME_NONNULL_END
