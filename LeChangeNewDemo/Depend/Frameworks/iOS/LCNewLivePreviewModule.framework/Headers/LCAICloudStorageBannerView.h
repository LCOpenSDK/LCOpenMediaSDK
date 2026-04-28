//
//  LCAICloudStorageBannerView.h
//  LCNewLivePreviewModule
//
//  实况云录像时间轴下方：「AI每日快看」「每日帧选」并排入口


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LCAICloudStorageBannerEntry) {
    LCAICloudStorageBannerEntrySilhouetteAlbum = 0, ///< AI每日快看 → 云录像集/摘要列表
    LCAICloudStorageBannerEntryDailyBrief = 1       ///< 每日帧选 → 帧录像列表
};

@interface LCAICloudStorageBannerView : UIView

@property (nonatomic, copy, nullable) void (^entryTapHandler)(LCAICloudStorageBannerEntry entry);

@end

NS_ASSUME_NONNULL_END
