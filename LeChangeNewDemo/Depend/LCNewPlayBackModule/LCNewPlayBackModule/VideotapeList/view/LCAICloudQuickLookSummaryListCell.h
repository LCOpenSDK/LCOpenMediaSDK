#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 每日快看摘要列表 Cell，布局与 RN `summaryListView.js` 中 renderItem 一致（含 tags / msgIconList 解析后的右侧图标行）。
@interface LCAICloudQuickLookSummaryListCell : UITableViewCell

/// 与 `registerClass:forCellReuseIdentifier:` 配套使用。
@property (class, nonatomic, copy, readonly) NSString *summaryListCellReuseIdentifier;

- (void)applyNetworkErrorState;

- (void)applyEmptySlotWithStartTime:(NSString *)startTime endTime:(NSString *)endTime;

- (void)applyContentWithStartTime:(NSString *)startTime
                            endTime:(NSString *)endTime
                            summary:(NSString *)summary
                           selected:(BOOL)selected
                   tagTypeStrings:(NSArray<NSString *> *)tagStrings;

/// 与 RN `resolveIconSource` 同管线，供每日帧选等独立列表复用。
+ (nullable UIImage *)ql_resolvedImageForTagItem:(id)tag;

@end

NS_ASSUME_NONNULL_END
