#import "LCAIFrameSelectEventPersenter.h"
#import <LCNetworkModule/LCCloudVideotapeInfo.h>
#import <LCNetworkModule/LCCondensedRecordInterface.h>
#import <LCNetworkModule/LCApplicationDataManager.h>
#import <LCMediaBaseModule/LCNewDeviceVideoManager.h>
#import <LCNetworkModule/LCDeviceInfo.h>
#import <LCBaseModule/LCError.h>

static NSInteger const kLCAIFrameSelectCondensedPageCount = 100;

@implementation LCAIFrameSelectEventPersenter

- (NSString *)quickLookPackageType {
    return @"aiInsight";
}

/// 不弹中间 loading；bitmap 完成后由宿主走 `mj_header` 触发 `fs_pullRefreshFirstPage`，与手动下拉一致
- (void)fetchCondensedRecordBitmap {
    if (!self.eventListPage) {
        return;
    }
    LCDeviceInfo *dev = [LCNewDeviceVideoManager shareInstance].currentDevice;
    if (!dev) {
        return;
    }
    if (self.dayItems.count < 2) {
        [self fs_notifyHostTriggerHeaderRefreshForList];
        return;
    }
    self.quickLookLoadFailed = NO;
    NSString *beginDay = self.dayItems.firstObject.dateString;
    NSString *endDay = self.dayItems.lastObject.dateString;
    NSString *cidForBitmap = self.selectedChannelId.length ? self.selectedChannelId : @"0";
    self.quickLookBitmapChannelId = [cidForBitmap copy];
    __weak typeof(self) weakSelf = self;
    [LCCondensedRecordInterface queryCondensedRecordBitmapWithToken:[LCApplicationDataManager token]
                                                            deviceId:dev.deviceId
                                                           channelId:cidForBitmap
                                                           productId:dev.productId
                                                            beginDay:beginDay
                                                              endDay:endDay
                                                         packageType:[self quickLookPackageType]
                                                             success:^(NSString *bitmap) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) selfRef = weakSelf;
            if (!selfRef) {
                return;
            }
            if (![selfRef mergeBitmapIfValid:bitmap]) {
                [selfRef fs_notifyHostTriggerHeaderRefreshForList];
                return;
            }
            [selfRef fs_notifyHostTriggerHeaderRefreshForList];
        });
    } failure:^(__unused LCError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) selfRef = weakSelf;
            if (!selfRef) {
                return;
            }
            [selfRef fs_notifyHostTriggerHeaderRefreshForList];
        });
    }];
}

- (void)fs_notifyHostTriggerHeaderRefreshForList {
    id<LCAIFrameSelectEventPresenterHost> h = (id<LCAIFrameSelectEventPresenterHost>)self.eventListPage;
    if ([(id)h respondsToSelector:@selector(lc_frameSelectTriggerHeaderRefreshForListLoad)]) {
        [h lc_frameSelectTriggerHeaderRefreshForListLoad];
    }
}

/// 与默认 `getCondensedRecords` 一致（`recordId=-1`、`count=100`），供日历 / 通道切换 / bitmap 回调使用
- (void)fetchCondensedListForCurrentDate {
    [self fs_requestCondensedListWithRecordId:@"-1" replaceAll:YES pullHeader:NO];
}

/// 下拉刷新：同首屏默认参数（`recordId=-1`）
- (void)fs_pullRefreshFirstPage {
    [self fs_requestCondensedListWithRecordId:@"-1" replaceAll:YES pullHeader:YES];
}

/// 上拉：以当前已加载数据中**时间序最后一条**的 `recordId` 作为下一页请求参数（与「第一页末条」起游标分页一致）
- (void)fs_loadMoreNextPage {
    NSString *rid = [self fs_recordIdAfterLastLoaded];
    if (rid.length == 0) {
        [self fs_callHostEndFooterNoMore:YES];
        return;
    }
    [self fs_requestCondensedListWithRecordId:rid replaceAll:NO pullHeader:NO];
}

- (void)fs_requestCondensedListWithRecordId:(NSString *)recordId replaceAll:(BOOL)replaceAll pullHeader:(BOOL)pullHeader {
    if (!self.eventListPage) {
        return;
    }
    NSString *rid = recordId.length ? recordId : @"-1";
    LCDeviceInfo *dev = [LCNewDeviceVideoManager shareInstance].currentDevice;
    NSString *begin = [NSString stringWithFormat:@"%@ 00:00:00", self.selectedDateStr];
    NSString *end = [NSString stringWithFormat:@"%@ 23:59:59", self.selectedDateStr];
    __weak typeof(self) weakSelf = self;
    [LCCondensedRecordInterface getCondensedRecordsWithToken:[LCApplicationDataManager token]
                                                    deviceId:dev.deviceId
                                                   channelId:self.selectedChannelId
                                                   productId:dev.productId
                                                   beginTime:begin
                                                     endTime:end
                                                    recordId:rid
                                               packageType:[self quickLookPackageType]
                                                     count:kLCAIFrameSelectCondensedPageCount
                                                   success:^(NSArray<LCCloudVideotapeInfo *> *records) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) selfRef = weakSelf;
            if (!selfRef) {
                return;
            }
            [selfRef.eventListPage lc_eventPersenterHostSetQuickLookLoadingVisible:NO];
            if (pullHeader) {
                [selfRef fs_callHostEndHeaderRefresh];
            }
            selfRef.quickLookHasLoaded = YES;
            selfRef.quickLookLoadFailed = NO;
            NSArray<LCCloudVideotapeInfo *> *incoming = records ?: @[];
            if (replaceAll) {
                selfRef.currentDateRecords = incoming;
            } else {
                selfRef.currentDateRecords = [selfRef fs_mergeDedupePreservingOrder:selfRef.currentDateRecords adding:incoming];
            }
            [selfRef rebuildQuickLookSummaryModels];
            [selfRef.eventListPage lc_eventPersenterHostApplyQuickLookAfterModelsChangedPlayRecord:[selfRef currentChannelRecord]];
            BOOL noMore = (incoming.count < kLCAIFrameSelectCondensedPageCount);
            [selfRef fs_callHostEndFooterNoMore:noMore];
        });
    } failure:^(LCError *__unused error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) selfRef = weakSelf;
            if (!selfRef) {
                return;
            }
            [selfRef.eventListPage lc_eventPersenterHostSetQuickLookLoadingVisible:NO];
            if (pullHeader) {
                [selfRef fs_callHostEndHeaderRefresh];
            } else if (replaceAll) {
                selfRef.quickLookLoadFailed = YES;
                selfRef.quickLookHasLoaded = YES;
                selfRef.currentDateRecords = @[];
                [selfRef rebuildQuickLookSummaryModels];
                [selfRef.eventListPage lc_eventPersenterHostApplyQuickLookAfterModelsChangedPlayRecord:[selfRef currentChannelRecord]];
            }
            [selfRef fs_callHostEndFooterNoMore:NO];
        });
    }];
}

- (void)fs_callHostEndHeaderRefresh {
    id<LCAIFrameSelectEventPresenterHost> h = (id<LCAIFrameSelectEventPresenterHost>)self.eventListPage;
    if ([(id)h respondsToSelector:@selector(lc_frameSelectEndHeaderRefresh)]) {
        [h lc_frameSelectEndHeaderRefresh];
    }
}

- (void)fs_callHostEndFooterNoMore:(BOOL)noMore {
    id<LCAIFrameSelectEventPresenterHost> h = (id<LCAIFrameSelectEventPresenterHost>)self.eventListPage;
    if ([(id)h respondsToSelector:@selector(lc_frameSelectEndFooterRefreshWithNoMoreData:)]) {
        [h lc_frameSelectEndFooterRefreshWithNoMoreData:noMore];
    }
}

- (NSString *)fs_recordIdAfterLastLoaded {
    NSArray<LCCloudVideotapeInfo *> *flat = [self fs_flatRecordsForSelectedChannelChronological];
    LCCloudVideotapeInfo *last = flat.lastObject;
    return last.recordId.length ? last.recordId : @"";
}

- (NSArray<LCCloudVideotapeInfo *> *)fs_flatRecordsForSelectedChannelChronological {
    NSMutableArray<LCCloudVideotapeInfo *> *clips = [NSMutableArray array];
    for (LCCloudVideotapeInfo *r in self.currentDateRecords) {
        if ([self fs_channelId:r.channelId matchesSelected:self.selectedChannelId]) {
            [clips addObject:r];
        }
    }
    [clips sortUsingComparator:^NSComparisonResult(LCCloudVideotapeInfo *a, LCCloudVideotapeInfo *b) {
        NSTimeInterval ta = [self unixFromCompactDateTimeYYYYMMDDThhmmss:a.createTime];
        NSTimeInterval tb = [self unixFromCompactDateTimeYYYYMMDDThhmmss:b.createTime];
        if (ta < tb) {
            return NSOrderedAscending;
        }
        if (ta > tb) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    return [clips copy];
}

- (NSArray<LCCloudVideotapeInfo *> *)fs_mergeDedupePreservingOrder:(NSArray<LCCloudVideotapeInfo *> *)existing adding:(NSArray<LCCloudVideotapeInfo *> *)batch {
    NSMutableOrderedSet<NSString *> *seen = [NSMutableOrderedSet orderedSet];
    NSMutableArray<LCCloudVideotapeInfo *> *out = [NSMutableArray array];
    void (^add)(LCCloudVideotapeInfo *) = ^(LCCloudVideotapeInfo *r) {
        NSString *k = r.recordId.length ? r.recordId : [NSString stringWithFormat:@"_ptr_%p", (void *)r];
        if ([seen containsObject:k]) {
            return;
        }
        [seen addObject:k];
        [out addObject:r];
    };
    for (LCCloudVideotapeInfo *r in existing) {
        add(r);
    }
    for (LCCloudVideotapeInfo *r in batch) {
        add(r);
    }
    return [out copy];
}

#pragma mark - aiInsight 平铺 clips

- (void)rebuildQuickLookSummaryModels {
    LCCloudVideotapeInfo *rec0 = [self currentChannelRecord];
    NSArray *nested = rec0 ? rec0.mp4Videos : nil;
    BOOL loadedOk = self.quickLookHasLoaded && !self.quickLookLoadFailed;
    BOOL hasNestedSegments = [nested isKindOfClass:[NSArray class]] && [(NSArray *)nested count] > 0;
    if (hasNestedSegments) {
        [super rebuildQuickLookSummaryModels];
        return;
    }

    NSMutableArray<LCCloudVideotapeInfo *> *clips = [NSMutableArray array];
    for (LCCloudVideotapeInfo *r in self.currentDateRecords) {
        if ([self fs_channelId:r.channelId matchesSelected:self.selectedChannelId]) {
            [clips addObject:r];
        }
    }
    [clips sortUsingComparator:^NSComparisonResult(LCCloudVideotapeInfo *a, LCCloudVideotapeInfo *b) {
        NSTimeInterval ta = [self unixFromCompactDateTimeYYYYMMDDThhmmss:a.createTime];
        NSTimeInterval tb = [self unixFromCompactDateTimeYYYYMMDDThhmmss:b.createTime];
        if (ta < tb) {
            return NSOrderedAscending;
        }
        if (ta > tb) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];

    self.quickLookSummaryEmptyBoard = loadedOk && (clips.count == 0);
    if (self.quickLookSummaryEmptyBoard) {
        self.sortedMp4Segments = @[];
        self.displaySummaryRows = @[];
        self.playSegmentRanges = @[];
        self.selectedSummaryIndex = NSNotFound;
        return;
    }

    NSMutableArray<NSDictionary *> *synthetic = [NSMutableArray array];
    for (LCCloudVideotapeInfo *clip in clips) {
        NSString *tp = [self fs_timePointHHmmFromCreateTime:clip.createTime];
        double dur = clip.videoLength;
        if (dur < 0.001) {
            dur = 1.0;
        }
        NSArray *tagArr = [self fs_tagArrayForInsightRecord:clip];
        NSMutableDictionary *seg = [@{
            @"timePoint" : tp,
            @"duration" : @(dur),
            @"summary" : @"",
            @"tags" : tagArr,
            @"frameSelectRecord" : clip,
        } mutableCopy];
        if (clip.thumbUrl.length) {
            seg[@"thumbUrl"] = clip.thumbUrl;
        }
        [synthetic addObject:seg];
    }
    self.sortedMp4Segments = [synthetic copy];

    NSMutableArray<NSDictionary *> *rows = [NSMutableArray array];
    for (NSInteger i = 0; i < (NSInteger)synthetic.count; i++) {
        NSDictionary *seg = synthetic[(NSUInteger)i];
        NSMutableDictionary *row = [[self contentDisplayRowForSegment:seg sortedIndex:i] mutableCopy];
        row[@"frameSelectRecord"] = seg[@"frameSelectRecord"];
        [rows addObject:row];
    }
    self.displaySummaryRows = [rows copy];
    self.playSegmentRanges = [self buildPlaySegmentRangesFromDisplayRows:self.displaySummaryRows];
    self.selectedSummaryIndex = [self firstContentDisplayRowIndex];
}

- (BOOL)fs_channelId:(NSString *)a matchesSelected:(NSString *)b {
    NSString *bs = b.length ? b : @"0";
    NSString *as = a.length ? a : @"0";
    if ([as isEqualToString:bs]) {
        return YES;
    }
    return [as integerValue] == [bs integerValue];
}

- (NSString *)fs_timePointHHmmFromCreateTime:(NSString *)ct {
    if (ct.length >= 13) {
        NSInteger h = [[ct substringWithRange:NSMakeRange(9, 2)] integerValue];
        NSInteger m = [[ct substringWithRange:NSMakeRange(11, 2)] integerValue];
        return [NSString stringWithFormat:@"%02ld:%02ld", (long)h, (long)m];
    }
    return @"00:00";
}

- (NSArray<NSString *> *)fs_tagArrayForInsightRecord:(LCCloudVideotapeInfo *)rec {
    if (rec.insightTypeTag.length) {
        return @[ rec.insightTypeTag ];
    }
    return @[];
}

@end
