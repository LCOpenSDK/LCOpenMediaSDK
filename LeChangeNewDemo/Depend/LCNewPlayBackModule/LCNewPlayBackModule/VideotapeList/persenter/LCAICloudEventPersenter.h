#import <Foundation/Foundation.h>
#import "LCAICloudDayItem.h"
#import <LCNetworkModule/LCCloudVideotapeInfo.h>

NS_ASSUME_NONNULL_BEGIN

@class LCAICloudEventListViewController;

@protocol LCAICloudEventPresenterHost <NSObject>
- (void)lc_eventPersenterHostSetQuickLookLoadingVisible:(BOOL)show;
- (void)lc_eventPersenterHostApplyQuickLookAfterModelsChangedPlayRecord:(LCCloudVideotapeInfo *_Nullable)record;
@end

@interface LCAICloudEventPersenter : NSObject

@property (nonatomic, weak) id<LCAICloudEventPresenterHost> eventListPage;

@property (nonatomic, strong) NSMutableArray<LCAICloudDayItem *> *dayItems;
@property (nonatomic, copy) NSArray<NSDictionary *> *displaySummaryRows;
@property (nonatomic, copy) NSArray<NSDictionary *> *playSegmentRanges;
@property (nonatomic, copy) NSString *selectedDateStr;
@property (nonatomic, copy) NSString *selectedChannelId;
@property (nonatomic, copy) NSString *quickLookBitmapChannelId;
@property (nonatomic, copy) NSArray<LCCloudVideotapeInfo *> *currentDateRecords;
@property (nonatomic, strong) NSArray<NSDictionary *> *sortedMp4Segments;
@property (nonatomic, assign) NSInteger selectedSummaryIndex;
@property (nonatomic, assign) BOOL quickLookLoadFailed;
@property (nonatomic, assign) BOOL quickLookHasLoaded;
@property (nonatomic, assign) BOOL quickLookSummaryEmptyBoard;

- (void)configureQuickLookInitialDataFromMainChannel;

- (void)buildLast30DaysPlain;

- (void)fetchCondensedRecordBitmap;

- (void)fetchCondensedListForCurrentDate;

- (void)clearListLoadFailureAndRefetch;

- (nullable LCCloudVideotapeInfo *)currentChannelRecord;

- (void)rebuildQuickLookSummaryModels;

- (NSString *)quickLookPackageType;

- (double)offsetSecondsForSummaryDisplayIndex:(NSInteger)displayIndex;

- (double)doubleValueFromId:(nullable id)o;

- (NSArray<NSString *> *)tagStringsFromRowTags:(nullable id)tags;

/// 与 RN `getSummaryTagList` 一致：`tags` 优先，否则 `msgIconList`；并回退到 segment 上的同名字段。
- (NSArray<NSString *> *)summaryTagStringsForDisplayRow:(NSDictionary *)row;

- (NSTimeInterval)quickLookStartUnixForRecord:(nullable LCCloudVideotapeInfo *)rec;

- (NSTimeInterval)ql_quickLookTimelineTotalSecondsForRecord:(nullable LCCloudVideotapeInfo *)rec;

- (NSArray<NSNumber *> *)ql_progressBarOverlayRatios;

- (BOOL)mergeBitmapIfValid:(NSString *)bitmap;

// MARK: 子类（如每日帧选）复用片段拼装
- (NSTimeInterval)unixFromCompactDateTimeYYYYMMDDThhmmss:(NSString *)s;
- (NSDictionary *)contentDisplayRowForSegment:(NSDictionary *)seg sortedIndex:(NSInteger)sortedIdx;
- (NSArray<NSDictionary *> *)buildPlaySegmentRangesFromDisplayRows:(NSArray<NSDictionary *> *)rows;
- (NSInteger)firstContentDisplayRowIndex;

@end

NS_ASSUME_NONNULL_END
