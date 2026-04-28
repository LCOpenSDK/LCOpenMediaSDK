//
//  LCCondensedRecordInterface.m
//  LCNetworkModule
//

#import "LCCondensedRecordInterface.h"
#import "LCNetworkRequestManager.h"
#import "TextDefine.h"
#import "LCCloudVideotapeInfo.h"
#import <LCBaseModule/LCError.h>

@implementation LCCondensedRecordInterface

+ (void)queryCondensedRecordBitmapWithToken:(NSString *)token
                                   deviceId:(NSString *)deviceId
                                  channelId:(NSString *)channelId
                                  productId:(NSString *)productId
                                  beginDay:(NSString *)beginDayYYYYMMDD
                                    endDay:(NSString *)endDayYYYYMMDD
                               packageType:(NSString *)packageType
                                     success:(void (^)(NSString *bitmap))success
                                     failure:(void (^)(LCError *error))failure {
    NSDictionary *params = @{
        KEY_TOKEN: token ?: @"",
        KEY_DEVICE_ID: deviceId ?: @"",
        KEY_CHANNEL_ID: channelId ?: @"",
        KEY_PRODUCT_ID: productId ?: @"",
        @"beginTime": beginDayYYYYMMDD ?: @"",
        @"endTime": endDayYYYYMMDD ?: @"",
        @"packageType": packageType ?: @"aiCloudRecord",
    };
    [[LCNetworkRequestManager manager] lc_POST:@"/queryCondensedRecordBitmap" parameters:params success:^(id _Nonnull objc) {
        if (![objc isKindOfClass:[NSDictionary class]]) {
            if (failure) {
                failure([LCError errorWithCode:@"-1" errorMessage:@"invalid response" errorInfo:nil]);
            }
            return;
        }
        NSString *bitmap = [(NSDictionary *)objc objectForKey:@"bitmap"] ?: @"";
        if (success) {
            success(bitmap);
        }
    } failure:^(LCError *_Nonnull error) {
        if (failure) {
            failure(error);
        }
    }];
}

+ (void)getCondensedRecordsWithToken:(NSString *)token
                            deviceId:(NSString *)deviceId
                           channelId:(NSString *)channelId
                           productId:(NSString *)productId
                           beginTime:(NSString *)beginTimeFull
                             endTime:(NSString *)endTimeFull
                            recordId:(NSString *)recordId
                           packageType:(NSString *)packageType
                                 count:(NSInteger)count
                                 success:(void (^)(NSArray<NSDictionary *> *records))success
                                 failure:(void (^)(LCError *error))failure {
    NSDictionary *params = @{
        KEY_TOKEN: token ?: @"",
        KEY_DEVICE_ID: deviceId ?: @"",
        KEY_CHANNEL_ID: channelId ?: @"",
        KEY_PRODUCT_ID: productId ?: @"",
        KEY_BEGIN_TIME: beginTimeFull ?: @"",
        KEY_END_TIME: endTimeFull ?: @"",
        @"recordId": recordId ?: @"-1",
        @"packageType": packageType ?: @"aiCloudRecord",
        KEY_COUNT: @(count),
    };
    [[LCNetworkRequestManager manager] lc_POST:@"/getCondensedRecords" parameters:params success:^(id _Nonnull objc) {
        if (![objc isKindOfClass:[NSDictionary class]]) {
            if (failure) {
                failure([LCError errorWithCode:@"-2" errorMessage:@"invalid response" errorInfo:nil]);
            }
            return;
        }
        NSArray *rawRecords = [(NSDictionary *)objc objectForKey:@"records"];
        if (![rawRecords isKindOfClass:[NSArray class]]) {
            rawRecords = @[];
        }
        /// 与 getCloudRecords 一致：MJ 映射为 LCCloudVideotapeInfo（含影集扩展字段）
        NSMutableArray<LCCloudVideotapeInfo *> *records = [LCCloudVideotapeInfo mj_objectArrayWithKeyValuesArray:rawRecords];
        if (success) {
            success(records ?: @[]);
        }
    } failure:^(LCError *_Nonnull error) {
        if (failure) {
            failure(error);
        }
    }];
}

@end
