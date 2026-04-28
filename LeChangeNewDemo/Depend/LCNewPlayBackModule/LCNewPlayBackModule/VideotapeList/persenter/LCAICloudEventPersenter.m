#import "LCAICloudEventPersenter.h"
#import <LCMediaBaseModule/LCNewDeviceVideoManager.h>
#import <LCNetworkModule/LCApplicationDataManager.h>
#import <LCNetworkModule/LCCondensedRecordInterface.h>
#import <LCNetworkModule/LCDeviceInfo.h>

static const NSInteger kLCAICloudQuickLookCalendarDayCount = 30;

@implementation LCAICloudEventPersenter

- (void)configureQuickLookInitialDataFromMainChannel {
    self.selectedChannelId = [LCNewDeviceVideoManager shareInstance].mainChannelInfo.channelId ?: @"0";
    self.quickLookBitmapChannelId = [self.selectedChannelId copy];
    self.dayItems = [NSMutableArray array];
    self.currentDateRecords = @[];
    self.sortedMp4Segments = @[];
    self.selectedSummaryIndex = NSNotFound;
    self.quickLookLoadFailed = NO;
    self.quickLookHasLoaded = NO;
    self.quickLookSummaryEmptyBoard = NO;
}

- (NSString *)quickLookPackageType {
    return @"aiCloudRecord";
}

- (void)buildLast30DaysPlain {
    [self.dayItems removeAllObjects];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *today = [NSDate date];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd";
    for (NSInteger i = kLCAICloudQuickLookCalendarDayCount - 1; i >= 0; i--) {
        NSDate *d = [cal dateByAddingUnit:NSCalendarUnitDay value:-i toDate:today options:0];
        LCAICloudDayItem *it = [LCAICloudDayItem new];
        it.dateString = [fmt stringFromDate:d];
        it.hasVideo = NO;
        [self.dayItems addObject:it];
    }
    self.selectedDateStr = [fmt stringFromDate:today];
}

- (void)fetchCondensedRecordBitmap {
    if (!self.eventListPage) {
        return;
    }
    LCDeviceInfo *dev = [LCNewDeviceVideoManager shareInstance].currentDevice;
    if (!dev) {
        return;
    }
    if (self.dayItems.count < 2) {
        [self.eventListPage lc_eventPersenterHostSetQuickLookLoadingVisible:NO];
        [self fetchCondensedListForCurrentDate];
        return;
    }
    [self.eventListPage lc_eventPersenterHostSetQuickLookLoadingVisible:YES];
    self.quickLookLoadFailed = NO;
    NSString *beginDay = self.dayItems.firstObject.dateString;
    NSString *endDay = self.dayItems.lastObject.dateString;
    NSString *cidForBitmap = self.quickLookBitmapChannelId.length ? self.quickLookBitmapChannelId : self.selectedChannelId;
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
                [selfRef.eventListPage lc_eventPersenterHostSetQuickLookLoadingVisible:NO];
                [selfRef fetchCondensedListForCurrentDate];
                return;
            }
            [selfRef fetchCondensedListForCurrentDate];
        });
    } failure:^(LCError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) selfRef = weakSelf;
            if (!selfRef) {
                return;
            }
            [selfRef.eventListPage lc_eventPersenterHostSetQuickLookLoadingVisible:NO];
            [selfRef fetchCondensedListForCurrentDate];
        });
    }];
}

- (BOOL)mergeBitmapIfValid:(NSString *)bitmap {
    if (bitmap.length != self.dayItems.count) {
        return NO;
    }
    [self.dayItems enumerateObjectsUsingBlock:^(LCAICloudDayItem *obj, NSUInteger idx, BOOL *stop) {
        (void)stop;
        unichar c = [bitmap characterAtIndex:idx];
        obj.hasVideo = (c == '1');
    }];
    return YES;
}

- (void)fetchCondensedListForCurrentDate {
    if (!self.eventListPage) {
        return;
    }
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
                                                    recordId:@"-1"
                                               packageType:[self quickLookPackageType]
                                                     count:100
                                                   success:^(NSArray<LCCloudVideotapeInfo *> *records) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) selfRef = weakSelf;
            if (!selfRef) {
                return;
            }
            [selfRef.eventListPage lc_eventPersenterHostSetQuickLookLoadingVisible:NO];
            selfRef.quickLookHasLoaded = YES;
            selfRef.quickLookLoadFailed = NO;
            selfRef.currentDateRecords = records ?: @[];
            [selfRef rebuildQuickLookSummaryModels];
            [selfRef.eventListPage lc_eventPersenterHostApplyQuickLookAfterModelsChangedPlayRecord:[selfRef currentChannelRecord]];
        });
    } failure:^(LCError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) selfRef = weakSelf;
            if (!selfRef) {
                return;
            }
            [selfRef.eventListPage lc_eventPersenterHostSetQuickLookLoadingVisible:NO];
            selfRef.quickLookLoadFailed = YES;
            selfRef.quickLookHasLoaded = YES;
            selfRef.currentDateRecords = @[];
            [selfRef rebuildQuickLookSummaryModels];
            [selfRef.eventListPage lc_eventPersenterHostApplyQuickLookAfterModelsChangedPlayRecord:[selfRef currentChannelRecord]];
        });
    }];
}

- (void)clearListLoadFailureAndRefetch {
    self.quickLookLoadFailed = NO;
    [self fetchCondensedListForCurrentDate];
}

- (nullable LCCloudVideotapeInfo *)currentChannelRecord {
    for (LCCloudVideotapeInfo *r in self.currentDateRecords) {
        NSString *cid = r.channelId.length ? r.channelId : @"";
        if ([cid isEqualToString:self.selectedChannelId]) {
            return r;
        }
    }
    return nil;
}

- (void)rebuildQuickLookSummaryModels {
    LCCloudVideotapeInfo *rec = [self currentChannelRecord];
    NSArray *raw = rec ? rec.mp4Videos : nil;
    BOOL loadedOk = self.quickLookHasLoaded && !self.quickLookLoadFailed;
    BOOL hasMp4List = [raw isKindOfClass:[NSArray class]] && [(NSArray *)raw count] > 0;
    self.quickLookSummaryEmptyBoard = loadedOk && !hasMp4List;

    NSMutableArray *arr = [NSMutableArray array];
    if (hasMp4List) {
        [arr addObjectsFromArray:raw];
        [arr sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            NSInteger ta = [self minutesFromTimePoint:a[@"timePoint"]];
            NSInteger tb = [self minutesFromTimePoint:b[@"timePoint"]];
            if (ta < tb) {
                return NSOrderedAscending;
            }
            if (ta > tb) {
                return NSOrderedDescending;
            }
            return NSOrderedSame;
        }];
    }
    self.sortedMp4Segments = arr;
    if (self.quickLookSummaryEmptyBoard) {
        self.displaySummaryRows = @[];
        self.playSegmentRanges = @[];
        self.selectedSummaryIndex = NSNotFound;
    } else {
        self.displaySummaryRows = [self buildDisplaySummaryRowsFromSortedSegments:arr];
        self.playSegmentRanges = [self buildPlaySegmentRangesFromDisplayRows:self.displaySummaryRows];
        self.selectedSummaryIndex = [self firstContentDisplayRowIndex];
    }
}


- (NSString *)normalizedHourMinuteFromTimePoint:(id)tp {
    if (![tp isKindOfClass:[NSString class]]) {
        return @"00:00";
    }
    NSArray<NSString *> *p = [(NSString *)tp componentsSeparatedByString:@":"];
    if (p.count < 2) {
        return @"00:00";
    }
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)[p[0] integerValue], (long)[p[1] integerValue]];
}

- (NSInteger)hourComponentFromTimePoint:(id)tp {
    NSString *s = [self normalizedHourMinuteFromTimePoint:tp];
    NSArray<NSString *> *p = [s componentsSeparatedByString:@":"];
    return p.count ? [p[0] integerValue] : 0;
}

- (NSDictionary *)contentDisplayRowForSegment:(NSDictionary *)seg sortedIndex:(NSInteger)sortedIdx {
    NSString *tp = [self normalizedHourMinuteFromTimePoint:seg[@"timePoint"]];
    NSInteger hour = [self hourComponentFromTimePoint:seg[@"timePoint"]];
    NSInteger nextH = hour + 1;
    NSString *endStr = (nextH < 24) ? [NSString stringWithFormat:@"%02ld:00", (long)nextH] : @"24:00";
    return @{
        @"empty" : @NO,
        @"startTime" : tp ?: @"",
        @"endTime" : endStr,
        @"summary" : seg[@"summary"] ?: @"",
        @"tags" : seg[@"tags"] ?: [NSNull null],
        @"msgIconList" : seg[@"msgIconList"] ?: [NSNull null],
        @"segment" : seg,
        @"sortedSegIndex" : @(sortedIdx),
    };
}

- (NSArray<NSDictionary *> *)buildDisplaySummaryRowsFromSortedSegments:(NSArray<NSDictionary *> *)sorted {
    NSMutableArray<NSDictionary *> *rows = [NSMutableArray array];
    if (sorted.count == 0) {
        [rows addObject:@{ @"empty" : @YES, @"startTime" : @"00:00", @"endTime" : @"24:00" }];
        return [rows copy];
    }
    NSString *firstTp = [self normalizedHourMinuteFromTimePoint:sorted[0][@"timePoint"]];
    if (![firstTp isEqualToString:@"00:00"]) {
        [rows addObject:@{
            @"empty" : @YES,
            @"startTime" : @"00:00",
            @"endTime" : firstTp,
        }];
    }
    [rows addObject:[self contentDisplayRowForSegment:sorted[0] sortedIndex:0]];
    for (NSInteger i = 1; i < (NSInteger)sorted.count; i++) {
        NSInteger prevHour = [self hourComponentFromTimePoint:sorted[i - 1][@"timePoint"]];
        NSInteger currHour = [self hourComponentFromTimePoint:sorted[i][@"timePoint"]];
        if (currHour > prevHour + 1) {
            NSString *gS = [NSString stringWithFormat:@"%02ld:00", (long)(prevHour + 1)];
            NSString *gE = [NSString stringWithFormat:@"%02ld:00", (long)currHour];
            [rows addObject:@{ @"empty" : @YES, @"startTime" : gS, @"endTime" : gE }];
        }
        [rows addObject:[self contentDisplayRowForSegment:sorted[i] sortedIndex:i]];
    }
    return [rows copy];
}

- (NSArray<NSDictionary *> *)buildPlaySegmentRangesFromDisplayRows:(NSArray<NSDictionary *> *)rows {
    NSMutableArray<NSDictionary *> *out = [NSMutableArray array];
    double acc = 0;
    NSInteger idx = 0;
    for (NSDictionary *r in rows) {
        if (![r[@"empty"] boolValue]) {
            NSDictionary *seg = r[@"segment"];
            double d = [self doubleValueFromId:seg[@"duration"]];
            [out addObject:@{ @"idx" : @(idx), @"min" : @(acc), @"max" : @(acc + d) }];
            acc += d;
        }
        idx++;
    }
    return [out copy];
}

- (NSInteger)firstContentDisplayRowIndex {
    NSInteger i = 0;
    for (NSDictionary *r in self.displaySummaryRows) {
        if (![r[@"empty"] boolValue]) {
            return i;
        }
        i++;
    }
    return NSNotFound;
}

- (NSArray<NSString *> *)tagStringsFromRowTags:(id)tags {
    if (tags == nil || tags == [NSNull null]) {
        return @[];
    }
    if ([tags isKindOfClass:[NSArray class]]) {
        NSMutableArray *m = [NSMutableArray array];
        for (id t in (NSArray *)tags) {
            if (t != nil && ![t isKindOfClass:[NSNull class]]) {
                NSString *s = [NSString stringWithFormat:@"%@", t];
                if (s.length) {
                    [m addObject:s];
                }
            }
        }
        return [m copy];
    }
    if ([tags isKindOfClass:[NSString class]]) {
        NSString *s = [(NSString *)tags stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (s.length == 0) {
            return @[];
        }
        if ([s hasPrefix:@"["]) {
            NSData *d = [s dataUsingEncoding:NSUTF8StringEncoding];
            if (d) {
                id j = [NSJSONSerialization JSONObjectWithData:d options:0 error:nil];
                if ([j isKindOfClass:[NSArray class]]) {
                    return [self tagStringsFromRowTags:j];
                }
            }
        }
        NSMutableArray *parts = [NSMutableArray array];
        for (NSString *x in [s componentsSeparatedByString:@","]) {
            NSString *t = [x stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (t.length) {
                [parts addObject:t];
            }
        }
        return [parts copy];
    }
    return @[ [NSString stringWithFormat:@"%@", tags] ];
}

- (NSArray<NSString *> *)summaryTagStringsForDisplayRow:(NSDictionary *)row {
    id raw = row[@"tags"];
    if (raw == nil || raw == [NSNull null]) {
        raw = row[@"msgIconList"];
    }
    if ((raw == nil || raw == [NSNull null]) && [row[@"segment"] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *seg = row[@"segment"];
        raw = seg[@"tags"];
        if (raw == nil || raw == [NSNull null]) {
            raw = seg[@"msgIconList"];
        }
    }
    return [self tagStringsFromRowTags:raw];
}

- (NSInteger)minutesFromTimePoint:(id)tp {
    if (![tp isKindOfClass:[NSString class]]) {
        return 0;
    }
    NSArray *p = [(NSString *)tp componentsSeparatedByString:@":"];
    if (p.count < 2) {
        return 0;
    }
    return [p[0] integerValue] * 60 + [p[1] integerValue];
}

- (double)offsetSecondsForSummaryDisplayIndex:(NSInteger)displayIndex {
    double sum = 0;
    for (NSInteger i = 0; i < displayIndex && i < (NSInteger)self.displaySummaryRows.count; i++) {
        NSDictionary *r = self.displaySummaryRows[i];
        if (![r[@"empty"] boolValue]) {
            NSDictionary *seg = r[@"segment"];
            sum += [self doubleValueFromId:seg[@"duration"]];
        }
    }
    return sum;
}

- (double)doubleValueFromId:(id)o {
    if ([o isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)o doubleValue];
    }
    if ([o isKindOfClass:[NSString class]]) {
        return [(NSString *)o doubleValue];
    }
    return 0;
}

- (NSTimeInterval)unixFromCreateTime:(NSString *)createTime {
    if (createTime.length == 0) {
        return 0;
    }
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *d = [f dateFromString:createTime];
    return d ? [d timeIntervalSince1970] : 0;
}

- (NSTimeInterval)unixFromCompactDateTimeYYYYMMDDThhmmss:(NSString *)s {
    if (s.length < 15 || [s characterAtIndex:8] != 'T') {
        return 0;
    }
    NSInteger year = [[s substringWithRange:NSMakeRange(0, 4)] integerValue];
    NSInteger month = [[s substringWithRange:NSMakeRange(4, 2)] integerValue];
    NSInteger day = [[s substringWithRange:NSMakeRange(6, 2)] integerValue];
    NSInteger hour = [[s substringWithRange:NSMakeRange(9, 2)] integerValue];
    NSInteger minute = [[s substringWithRange:NSMakeRange(11, 2)] integerValue];
    NSInteger second = [[s substringWithRange:NSMakeRange(13, 2)] integerValue];
    NSDateComponents *c = [[NSDateComponents alloc] init];
    c.year = year;
    c.month = month;
    c.day = day;
    c.hour = hour;
    c.minute = minute;
    c.second = second;
    NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDate *d = [cal dateFromComponents:c];
    return d ? floor([d timeIntervalSince1970]) : 0;
}

- (NSTimeInterval)ql_quickLookTimelineTotalSecondsForRecord:(LCCloudVideotapeInfo *)rec {
    double t = rec.videoLength;
    if (t < 0.001) {
        t = 0.001;
    }
    return t;
}

- (NSArray<NSNumber *> *)ql_progressBarOverlayRatios {
    LCCloudVideotapeInfo *rec = [self currentChannelRecord];
    if (!rec || self.sortedMp4Segments.count == 0) {
        return @[];
    }
    double total = [self ql_quickLookTimelineTotalSecondsForRecord:rec];
    double acc = 0;
    NSMutableArray<NSNumber *> *out = [NSMutableArray array];
    for (NSDictionary *item in self.sortedMp4Segments) {
        acc += [self doubleValueFromId:item[@"duration"]];
        double r = acc / total;
        if (r < 0) {
            r = 0;
        } else if (r > 1) {
            r = 1;
        }
        [out addObject:@(round(r * 10000.0) / 10000.0)];
    }
    return [out copy];
}

- (NSTimeInterval)quickLookStartUnixForRecord:(LCCloudVideotapeInfo *)rec {
    if (!rec) {
        return 0;
    }
    NSString *ct = rec.createTime.length ? rec.createTime : rec.beginTime;
    if (ct.length == 15 && [ct containsString:@"T"]) {
        NSTimeInterval u = [self unixFromCompactDateTimeYYYYMMDDThhmmss:ct];
        if (u > 0) {
            return u;
        }
    }
    NSDate *bd = rec.beginDate;
    if (bd) {
        return floor([bd timeIntervalSince1970]);
    }
    return [self unixFromCreateTime:ct ?: @""];
}

@end
