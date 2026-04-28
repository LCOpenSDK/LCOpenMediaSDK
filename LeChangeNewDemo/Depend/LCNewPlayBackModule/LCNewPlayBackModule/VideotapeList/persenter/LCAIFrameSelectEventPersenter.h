#import "LCAICloudEventPersenter.h"

NS_ASSUME_NONNULL_BEGIN

/// 每日帧选列表宿主：下拉 / 上拉结束回调（与 `LCNewVideotapeListViewController` + MJRefresh 用法一致）
@protocol LCAIFrameSelectEventPresenterHost <LCAICloudEventPresenterHost>
/// bitmap 就绪后由 Presenter 调用：触发 `mj_header` 拉列表（替代页面中间 loading）
- (void)lc_frameSelectTriggerHeaderRefreshForListLoad;
- (void)lc_frameSelectEndHeaderRefresh;
/// `noMore == YES` 时 `endRefreshingWithNoMoreData`，否则仅 `endRefreshing`
- (void)lc_frameSelectEndFooterRefreshWithNoMoreData:(BOOL)noMore;
@end

/// 每日帧选：与每日快看相同影集/日历协议，但 `packageType` 为 `aiInsight`；列表支持分页（`recordId` 游标）。
@interface LCAIFrameSelectEventPersenter : LCAICloudEventPersenter

/// 下拉刷新：与 `fetchCondensedListForCurrentDate` 相同参数（`recordId = -1`、默认 `count`）
- (void)fs_pullRefreshFirstPage;

/// 上拉加载：将当前已加载列表中**最后一条**的 `recordId` 作为下一页 `recordId` 传入（与首拉后「第一页末条」游标一致）
- (void)fs_loadMoreNextPage;

@end

NS_ASSUME_NONNULL_END
